
class InvoicesForEntitiesWorker
  include Sidekiq::Worker
  include Support::Profiling

  def perform(project_anchor_id, year, quarter, org_unit_ids)
    profile("InvoicesForEntitiesWorker") do
      do_perform(project_anchor_id, year, quarter, org_unit_ids)
    end
  end

  def do_perform(project_anchor_id, year, quarter, org_unit_ids)
    project_anchor = ProjectAnchor.find(project_anchor_id)

    puts "************ invoices for #{project_anchor_id} - #{year}/Q#{quarter} -  #{org_unit_ids}"
    invoicing_request = InvoicingRequest.new(year: year, quarter: quarter)

    project_finder = project_finder(project_anchor, invoicing_request)
    project = project_finder.find_project(nil, invoicing_request.end_date_as_date)
    invoicing_request.project = project
    org_units_by_id = fetch_org_units(invoicing_request, org_unit_ids)

    analytics_service = analytics_service(invoicing_request, org_unit_ids)

    invoices = {}
    org_unit_ids.each do |org_unit_id|
      org_unit = org_units_by_id[org_unit_id]
      begin
        profile("calculate invoices #{org_unit_id}") do
          orgunit_invoices = calculate_invoices(invoicing_request, org_unit, analytics_service, project_finder)
          invoices[org_unit_id] = orgunit_invoices
        end
      rescue Invoicing::InvoicingError => e
        puts e.message
      end
    end
    publish(project, invoices.values.flatten)
  end

  def project_finder(project_anchor, invoicing_request)
    profile("load Project") do
      ConstantProjectFinder.new(
        Hash[invoicing_request.quarter_dates.map do |date|
               project = project_anchor.projects.fully_loaded.for_date(date) || project_anchor.latest_draft
               [date, project]
             end
        ]
      )
    end
  end

  def analytics_service(invoicing_request, org_unit_ids)
    values = profile("fetch_values for #{org_unit_ids.size}") do
      fetch_values(invoicing_request, org_unit_ids)
    end

    # TODO: indicators might have changed over time
    indicators_expressions = profile("indicators_expressions") do
      fetch_indicators_expressions(invoicing_request)
    end

    values += Analytics::IndicatorCalculator.new.calculate(indicators_expressions, values)
    Analytics::CachedAnalyticsService.new([], values)
  end

  def publish(project, all_invoices)
    puts "generated #{all_invoices.size} invoices"
    publishers = [
      Publishing::DummyInvoicePublisher.new,
      Publishing::Dhis2InvoicePublisher.new
    ]
    publishers.each do |publisher|
      profile("publish #{all_invoices.size} invoices ") do
        publisher.publish(project, all_invoices)
      end
    end
  end

  def calculate_invoices(invoicing_request, org_unit, analytics_service, project_finder)
    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map { |n| n["id"] })
    # TODO: don't use constant project finder but based on date
    invoice_builder = Invoicing::InvoiceBuilder.new(project_finder, Tarification::TarificationService.new)

    invoices = []
    invoicing_request.quarter_dates.each do |month|
      monthly_invoice = invoice_builder.generate_monthly_entity_invoice(invoicing_request.project, entity, analytics_service, month)
      monthly_invoice.dump_invoice
      invoices << monthly_invoice
    end
    quarterly_invoices = invoice_builder.generate_quarterly_entity_invoice(invoicing_request.project, entity, analytics_service, invoicing_request.end_date_as_date)
    invoices << quarterly_invoices
    invoices.flatten
  end

  def fetch_org_units(invoicing_request, ids)
    profile("fetch_org_units") do
      pyramid = invoicing_request.project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
      pyramid.org_units(ids).index_by(&:id)
    end
  end

  def fetch_indicators_expressions(invoicing_request)
    indicator_ids = invoicing_request.project.activities.flat_map(&:activity_states).select(&:kind_indicator?).map(&:external_reference)
    return {} if indicator_ids.empty?
    data_compound = invoicing_request.project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    indicators = data_compound.indicators(indicator_ids)
    Hash[indicators.map { |indicator| [indicator.id, Analytics::IndicatorCalculator.parse_expression(indicator.numerator)] }]
  end

  def fetch_values(invoicing_request, org_unit_ids)
    dhis2 = invoicing_request.project.dhis2_connection
    packages = invoicing_request.project.packages
    dataset_ids = packages.flat_map(&:package_states).map(&:ds_external_reference).reject(&:nil?)

    values_query = {
      organisation_unit: org_unit_ids,
      data_sets:         dataset_ids,
      start_date:        invoicing_request.start_date_as_date,
      end_date:          invoicing_request.end_date_as_date,
      children:          false
    }
    values = dhis2.data_value_sets.list(values_query)
    values.data_values ? values.values : []
  end
end
