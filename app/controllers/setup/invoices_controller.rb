class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    @invoicing_request = InvoicingRequest.new(
      project: current_project,
      year:    params[:year] || Date.today.to_date.year,
      quarter: params[:quarter] || (Date.today.to_date.month / 4) + 1,
      entity:  params[:entity]
    )
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))

    pyramid = project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
    pyramid ||= Pyramid.from(project)
    @pyramid = pyramid

    @datacompound = project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    @datacompound ||= DataCompound.from(project)

    org_unit = pyramid.org_unit(invoicing_request.entity)
    @org_unit = org_unit

    render(:new) && return unless org_unit

    @org_unit_summaries = [
      org_unit.name,
      "parents : " + pyramid.org_unit_parents(org_unit.id).map(&:name).join(" > "),
      "groups : " + pyramid.org_unit_groups_of(org_unit).compact.map(&:name).join(", "),
      "date range : " + project.date_range(invoicing_request.year_quarter).map(&:to_s).join(", "),
      "periods : " + project.periods(invoicing_request.year_quarter).map(&:to_dhis2).join(", "),
      "facts : " + Invoicing::EntityBuilder.new.to_entity(org_unit).facts.map(&:to_s).join(", ")
    ]

    if params[:push_to_dhis2]
      InvoiceForProjectAnchorWorker.perform_async(
        project.project_anchor_id,
        invoicing_request.year,
        invoicing_request.quarter,
        [org_unit.id]
      )
      flash[:alert] = "Worker scheduled for #{org_unit.name} : #{invoicing_request.year}Q#{invoicing_request.quarter}"
      render(:new)
      return
    end

    options = {
      publisher_ids: [],
      mock_values:   invoicing_request.mock_values == "1"
    }

    if params[:simulate_draft]
      options = options.merge(
        force_project_id:       project.id,
        allow_fresh_dhis2_data: true
      )
    end

    invoicing_request.invoices = InvoicesForEntitiesWorker.new.do_perform(
      project.project_anchor_id,
      invoicing_request.year,
      invoicing_request.quarter,
      [org_unit.id],
      options
    )[org_unit.id]

    invoicing_request.invoices = invoicing_request.invoices.sort_by(&:date)

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
