
class InvoicesForEntitiesWorker
  include Sidekiq::Worker
  include Support::Profiling

  OrgUnitAndPackages = Struct.new(:org_unit, :org_units_by_package)

  def perform(project_anchor_id, year, quarter, org_unit_ids, options = {})
    profile("InvoicesForEntitiesWorker") do
      do_perform(project_anchor_id, year, quarter, org_unit_ids, options)
    end
  end

  def do_perform(project_anchor_id, year, quarter, org_unit_ids, arg_options = {})
    default_options = {
      publisher_ids:          %w[dummy dhis2],
      mock_values:            false,
      force_project_id:       nil,
      allow_fresh_dhis2_data: false
    }
    options = default_options.merge(arg_options)
    project_anchor = ProjectAnchor.find(project_anchor_id)

    puts "************ invoices for #{project_anchor_id} - #{year}/Q#{quarter} -  #{org_unit_ids}"
    invoicing_request = InvoicingRequest.new(year: year, quarter: quarter)

    project_finder = project_finder(project_anchor, invoicing_request, options)
    invoicing_request.project = project_finder.find_project(nil, invoicing_request.end_date_as_date)

    org_unit_and_packages = fetch_org_units_by_package(invoicing_request, org_unit_ids, options)
    analytics_service_by_org_unit_id = analytics_services_by_org_unit_id(invoicing_request, org_unit_and_packages, options)

    invoices = {}
    org_unit_and_packages.each do |org_unit_and_package|
      begin
        org_unit = org_unit_and_package.org_unit
        profile("calculate invoices #{org_unit.id}") do
          analytics_service = analytics_service_by_org_unit_id[org_unit.id]
          orgunit_invoices = calculate_invoices(
            invoicing_request,
            org_unit,
            analytics_service,
            project_finder
          )
          invoices[org_unit.id] = orgunit_invoices
        end
      rescue Invoicing::InvoicingError => e
        puts e.message
      end
    end
    publish(options[:publisher_ids], invoicing_request.project, invoices.values.flatten)
    invoices
  end

  def project_finder(project_anchor, invoicing_request, options)
    profile("load Project") do
      if options[:force_project_id]
        draft = project_anchor.projects.fully_loaded.find(options[:force_project_id])
        ConstantProjectFinder.new(
          Hash[invoicing_request.quarter_dates.map { |date| [date, draft] }]
        )
      else
        ConstantProjectFinder.new(
          Hash[invoicing_request.quarter_dates.map do |date|
                 project = project_anchor.projects.fully_loaded.for_date(date) || project_anchor.latest_draft
                 [date, project]
               end
          ]
        )
      end
    end
  end

  def analytics_services_by_org_unit_id(invoicing_request, org_unit_and_packages, options)
    values = profile("fetch_values for #{org_unit_and_packages.size}") do
      fetch_values(invoicing_request, org_unit_and_packages, options)
    end

    # TODO: indicators might have changed over time
    indicators_expressions = profile("indicators_expressions") do
      fetch_indicators_expressions(invoicing_request, options)
    end

    values += Analytics::IndicatorCalculator.new.calculate(indicators_expressions, values)

    data_compound = invoicing_request.project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    data_compound ||= DataCompound.from(invoicing_request.project) if options[:allow_fresh_dhis2_data]

    aggregation_per_data_elements = data_compound.data_elements.map { |de| [de.id, de.aggregation_type] }.to_h

    org_unit_and_packages.map do |ou_and_packages|
      [
        ou_and_packages.org_unit.id,
        Analytics::CachedAnalyticsService.new(
          ou_and_packages.org_unit,
          ou_and_packages.org_units_by_package,
          values,
          aggregation_per_data_elements
        )
      ]
    end.to_h
  end

  def publishers(publisher_ids)
    publishers = {
      "dummy" => Publishing::DummyInvoicePublisher.new,
      "dhis2" => Publishing::Dhis2InvoicePublisher.new
    }
    (publishers.keys & publisher_ids).map { |id| publishers[id] }
  end

  def publish(publisher_ids, project, all_invoices)
    puts "generated #{all_invoices.size} invoices"

    publishers(publisher_ids).each do |publisher|
      profile("publish #{all_invoices.size} invoices ") do
        publisher.publish(project, all_invoices)
      end
    end
  end

  def calculate_invoices(invoicing_request, org_unit, analytics_service, project_finder)
    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map { |n| n["id"] }, to_facts(org_unit))
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

  def fetch_org_units_by_package(invoicing_request, ids, options)
    profile("fetch_org_units") do
      pyramid = invoicing_request.project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
      pyramid ||= Pyramid.from(invoicing_request.project) if options[:allow_fresh_dhis2_data]
      ids.map do |id|
        org_unit = pyramid.org_unit(id)
        org_units_by_package = org_units_by_package(invoicing_request.project, pyramid, org_unit)
        OrgUnitAndPackages.new(org_unit, org_units_by_package)
      end
    end
  end

  def org_units_by_package(project, pyramid, org_unit)
    project.packages.map do |package|
      [package, package.linked_org_units(org_unit, pyramid)]
    end.to_h
  end

  def fetch_indicators_expressions(invoicing_request, options)
    indicator_ids = invoicing_request.project.activities.flat_map(&:activity_states).select(&:kind_indicator?).map(&:external_reference)
    return {} if indicator_ids.empty?
    data_compound = invoicing_request.project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    data_compound ||= DataCompound.from(invoicing_request.project) if options[:allow_fresh_dhis2_data]
    indicators = data_compound.indicators(indicator_ids)
    Hash[indicators.map { |indicator| [indicator.id, Analytics::IndicatorCalculator.parse_expression(indicator.numerator)] }]
  end

  def fetch_values(invoicing_request, org_unit_and_packages, options)
    if options[:mock_values] == true
      puts "using mock values !"
      return org_unit_and_packages.map { |ou| mock_values(invoicing_request, ou.org_units_by_package) }.flatten
    end
    dhis2 = invoicing_request.project.dhis2_connection
    packages = invoicing_request.project.packages
    dataset_ids = packages.flat_map(&:package_states).map(&:ds_external_reference).reject(&:nil?)
    org_unit_ids = org_unit_and_packages.flat_map(&:org_units_by_package).flat_map(&:values).flatten.flat_map(&:id).uniq

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

  def mock_values(invoicing_request, org_units_by_package)
    values = []
    org_units_by_package.each do |package, org_units|
      invoicing_request.quarter_dates.map { |date| "#{date.year}#{date.month.to_s.rjust(2, '0')}" }.each do |period|
        package.activities.each do |activity|
          package.states.each do |state|
            org_units.each do |org_unit_to_mock|
              activity_state = activity.activity_state(state)
              next unless activity_state
              value = if state.code == "tarif"
                        11
                      else
                        6 + rand(5)
                      end
              values.push OpenStruct.new(
                data_element: activity_state.external_reference,
                period:       period,
                org_unit:     org_unit_to_mock.id,
                value:        value
              )
            end
          end
        end
      end
    end
    values
  end

  def to_facts(org_unit)
    parent_ids = org_unit.path.split("/").reject(&:empty?)
    facts = parent_ids.each_with_index.map { |parent_id, index| ["level_#{index + 1}", parent_id] }.to_h
    facts
  end
end
