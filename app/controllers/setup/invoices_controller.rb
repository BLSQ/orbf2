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

    @org_unit_summaries = [
      org_unit.name,
      "parents : " + pyramid.org_unit_parents(org_unit.id).map(&:name).join(" > "),
      "groups : " + pyramid.org_unit_groups_of(org_unit).map(&:name).join(", ")
    ]

    invoicing_request.invoices = InvoicesForEntitiesWorker.new.do_perform(
      project.project_anchor_id,
      invoicing_request.year,
      invoicing_request.quarter,
      [org_unit.id],
      publisher_ids:          [],
      mock_values:            invoicing_request.mock_values == "1",
      force_project_id:       project.id,
      allow_fresh_dhis2_data: true
    )[org_unit.id]

    render :new
  end

  private

  def invoice_params
    params.require(:invoicing_request)
          .permit(:entity,
                  :year,
                  :quarter,
                  :mock_values)
  end
end
