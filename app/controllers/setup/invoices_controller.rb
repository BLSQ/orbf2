class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    @invoicing_request = InvoicingRequest.new(
      project: current_project,
      year:    Date.today.to_date.year,
      quarter: (Date.today.to_date.month / 4) + 1
    )
  end

  def create
    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: current_project))

    dhis2 = current_project.dhis2_connection
    org_unit = dhis2.organisation_units.find("CV4IXOSr5ky")
    org_unit_ids = [org_unit.id]

    packages = current_project.packages # .select { |p| p.apply_for_org_unit(org_unit) }
    dataset_ids = packages.flat_map(&:package_states).map(&:ds_external_reference).reject(&:nil?)

    values_query = {
      organisation_unit: org_unit_ids,
      data_sets:         dataset_ids,
      start_date:        invoicing_request.start_date_as_date,
      end_date:          invoicing_request.end_date_as_date,
      children:          false
    }
    values = dhis2.data_value_sets.list(values_query)
    @values = values.data_values ? values.values : []

    @values.group_by { |v| [v["data_element"], v["period"]] }.each do |k, v|
      puts "#{k} => #{v.size}\n\t #{v.first} \n\t #{v.last} "
    end

    project = current_project
    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map {|n| n["id"]})
    invoice_builder = Invoicing::InvoiceBuilder.new(ConstantProjectFinder.new(project), Tarification::TarificationService.new)
    analytics_service = Analytics::CachedAnalyticsService.new([org_unit], @values)

    invoicing_request.invoices = []
    [
      invoicing_request.end_date_as_date - 2.months,
      invoicing_request.end_date_as_date - 1.month,
      invoicing_request.end_date_as_date
    ].map(&:end_of_month).each do |month|
      monthly_invoice = invoice_builder.generate_monthly_entity_invoice(project, entity, analytics_service, month)
      monthly_invoice.dump_invoice
      invoicing_request.invoices << monthly_invoice
    end
    quarterly_invoice = invoice_builder.generate_quarterly_entity_invoice(project, entity, analytics_service, Date.today.end_of_month)

    invoicing_request.invoices << quarterly_invoice
    invoicing_request.invoices = invoicing_request.invoices.flatten

    render :new
  end

  private

  def invoice_params
    params.require(:invoicing_request)
          .permit(:entity,
                  :year,
                  :quarter)
  end
end
