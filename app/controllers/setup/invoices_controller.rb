class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    @invoicing_request = InvoicingRequest.new(
      project: current_project,
      year:    Date.today.to_date.year,
      quarter: (Date.today.to_date.month / 3) + 1,
      entity:  "CV4IXOSr5ky"
    )
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))

    org_unit = fetch_org_unit(project, invoicing_request.entity)
    values = fetch_values(project, [org_unit.id])
    indicators_expressions = fetch_indicators_expressions(project)
    puts "VALUES ::: #{JSON.pretty_generate(values)}"
    invoicing_request.invoices = calculate_invoices(project, org_unit, values, indicators_expressions)

    render :new
  end

  private

  def fetch_org_unit(project, id)
    # TODO: use snapshots
    project.dhis2_connection.organisation_units.find(id)
  end

  def fetch_indicators_expressions(project)
    # TODO: use snapshots
    indicator_ids = project.activities.flat_map(&:activity_states).select(&:kind_indicator?).map(&:external_reference)
    # indicator_ids += ["sJZI0t71kK7"]  TODO: remove me
    return {} if indicator_ids.empty?
    indicators = project.dhis2_connection.indicators.find(indicator_ids)
    Hash[indicators.map { |indicator| [indicator.id, Analytics::IndicatorCalculator.parse_expression(indicator.numerator)] }]
  end

  def calculate_invoices(project, org_unit, values, indicators_expressions)
    values += Analytics::IndicatorCalculator.new.calculate(indicators_expressions, values)

    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map { |n| n["id"] })
    invoice_builder = Invoicing::InvoiceBuilder.new(ConstantProjectFinder.new(project), Tarification::TarificationService.new)
    analytics_service = Analytics::CachedAnalyticsService.new([org_unit], values)

    invoices = []
    invoicing_request.quarter_dates.each do |month|
      monthly_invoice = invoice_builder.generate_monthly_entity_invoice(project, entity, analytics_service, month)
      monthly_invoice.dump_invoice
      invoices << monthly_invoice
    end
    puts "..... generated #{invoices.size} monthly "
    quarterly_invoices = invoice_builder.generate_quarterly_entity_invoice(project, entity, analytics_service, invoicing_request.end_date_as_date)
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

  def invoice_params
    params.require(:invoicing_request)
          .permit(:entity,
                  :year,
                  :quarter)
  end
end
