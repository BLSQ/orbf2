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

    org_unit = dhis2.organisation_units.find("wp2D6uvatyy")
    packages = current_project.packages.select{ |p| p.apply_for_org_unit(org_unit) }
    dataset_ids = packages.flat_map(&:package_states).map(&:ds_external_reference)

    byebug
    values_query = {
      organisation_unit: org_unit_ids,
      data_sets:         dataset_ids,
      start_date:        start_date_as_date,
      end_date:          end_date_as_date
    }
    values = dhis2.data_value_sets.list(values_query)
    values.data_values ? values.values : []

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
