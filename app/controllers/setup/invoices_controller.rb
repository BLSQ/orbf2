class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    @invoicing_request = InvoicingRequest.new(
      project: current_project,
      year:    Date.today.to_date.year,
      quarter: (Date.today.to_date.month / 4) + 1,
      entity:  "foYdyvZdi5e"
    )
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))

    pyramid = project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
    pyramid ||= Pyramid.from(project)

    org_unit = pyramid.org_unit(invoicing_request.entity)

    data_compound = project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    data_compound ||= DataCompound.from(project)

    aggregation_per_data_elements = data_compound.data_elements.map { |de| [de.id, de.aggregation_type] }.to_h

    org_units_by_package = org_units_by_package(project, pyramid, org_unit)
    values = if invoicing_request.mock_values == "1"
               mock_values(org_units_by_package)
             else
               fetch_values(project, org_units_by_package.values.flatten.map(&:id))
            end

    @org_unit_summaries = [
      org_unit.name,
      "parents : " + pyramid.org_unit_parents(org_unit.id).map(&:name).join(" > "),
      "groups : " + pyramid.org_unit_groups_of(org_unit).map(&:name).join(", ")
    ]

    indicators_expressions = fetch_indicators_expressions(project)
    invoicing_request.invoices = calculate_invoices(
      invoicing_request,
      org_unit,
      org_units_by_package,
      values,
      indicators_expressions,
      aggregation_per_data_elements
    )

    render :new
  end

  private

  def mock_values(org_units_by_package)
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
                        20 + rand(5)
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

  def org_units_by_package(project, pyramid, org_unit)
    project.packages.map do |package|
      [package, package.linked_org_units(org_unit, pyramid)]
    end.to_h
  end

  def fetch_indicators_expressions(project)
    # TODO: use snapshots
    indicator_ids = project.activities.flat_map(&:activity_states).select(&:kind_indicator?).map(&:external_reference)
    return {} if indicator_ids.empty?
    indicators = project.dhis2_connection.indicators.find(indicator_ids)
    Hash[indicators.map { |indicator| [indicator.id, Analytics::IndicatorCalculator.parse_expression(indicator.numerator)] }]
  end

  def calculate_invoices(invoicing_request, org_unit, org_units_by_package, values, indicators_expressions, aggregation_per_data_elements)
    values += Analytics::IndicatorCalculator.new.calculate(indicators_expressions, values)

    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map { |n| n["id"] }, to_facts(org_unit))
    project_finder = ConstantProjectFinder.new(
      Hash[invoicing_request.quarter_dates.map { |date| [date, invoicing_request.project] }]
    )
    invoice_builder = Invoicing::InvoiceBuilder.new(project_finder, Tarification::TarificationService.new)
    analytics_service = Analytics::CachedAnalyticsService.new(org_unit, org_units_by_package, values, aggregation_per_data_elements)

    invoices = []
    invoicing_request.quarter_dates.each do |month|
      monthly_invoice = invoice_builder.generate_monthly_entity_invoice(
        invoicing_request.project,
        entity,
        analytics_service,
        month
      )
      monthly_invoice.dump_invoice
      invoices << monthly_invoice
    end
    puts "..... generated #{invoices.size} monthly "
    quarterly_invoices = invoice_builder.generate_quarterly_entity_invoice(
      invoicing_request.project,
      entity,
      analytics_service,
      invoicing_request.end_date_as_date
    )
    puts "..... generated #{quarterly_invoices.size} quaterly "
    invoices << quarterly_invoices
    invoices.flatten
   end

  def fetch_values(project, org_unit_ids)
    dhis2 = project.dhis2_connection
    packages = project.packages
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

  def to_facts(org_unit)
    parent_ids = org_unit.path.split("/").reject(&:empty?)
    facts = parent_ids.each_with_index.map { |parent_id, index| ["level_#{index + 1}", parent_id] }.to_h
    facts
  end

  def invoice_params
    params.require(:invoicing_request)
          .permit(:entity,
                  :year,
                  :quarter,
                  :mock_values)
  end
end