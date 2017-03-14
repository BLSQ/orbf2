class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    @invoicing_request = InvoicingRequest.new(
      project: current_project,
      year:    Date.today.to_date.year,
      quarter: (Date.today.to_date.month / 4) + 1,
      entity:  "CV4IXOSr5ky"
    )
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))


    timing = Benchmark.bm do |x|
      org_unit = nil
      x.report("org_unit:") do
          org_unit = fetch_org_unit(project,invoicing_request.entity)
      end
      values = nil
      x.report("values:") do
        values = fetch_values(project, [org_unit.id])
      end
      x.report("calculate_invoices:") do
        invoicing_request.invoices = calculate_invoices(project, org_unit, values)
      end
    end

    puts "!!!! Invoiced in"
    puts timing

    render :new
  end

  private

  def fetch_org_unit(project,id)
    project.dhis2_connection.organisation_units.find(id)
  end

  def calculate_invoices(project, org_unit, values)
    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map { |n| n["id"] })
    invoice_builder = Invoicing::InvoiceBuilder.new(ConstantProjectFinder.new(project), Tarification::TarificationService.new)
    analytics_service = Analytics::CachedAnalyticsService.new([org_unit], values)

    invoices = []
    invoicing_request.quarter_dates.each do |month|
      monthly_invoice = invoice_builder.generate_monthly_entity_invoice(project, entity, analytics_service, month)
      monthly_invoice.dump_invoice
      invoices << monthly_invoice
    end
    quarterly_invoice = invoice_builder.generate_quarterly_entity_invoice(project, entity, analytics_service, invoicing_request.end_date_as_date)

    invoices << quarterly_invoice
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
