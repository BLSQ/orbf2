class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    project = current_project(project_scope: :fully_loaded) if params["calculate"]
    @invoicing_request = InvoicingRequest.new(
      project: current_project,
      year:    params[:year] || Date.today.to_date.year,
      quarter: params[:quarter] || (Date.today.to_date.month / 4) + 1,
      entity:  params[:entity],
      legacy_engine:  params[:legacy_engine] ? params[:legacy_engine]=="true" : true
    )
    if params["calculate"]
      render_invoice(project, invoicing_request)
      return
    end
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))
    render_invoice(project, invoicing_request)
  end

  private

  def render_invoice(project, invoicing_request)

    if invoicing_request.legacy_engine?
      render_legacy_invoice(project, invoicing_request)
    else
      render_new_invoice(project, invoicing_request)
    end
  end

def render_new_invoice(project, invoicing_request)

  orbf_project = MapProjectToOrbfProject.new(project).map
  fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(orbf_project, invoicing_request.entity, invoicing_request.year_quarter.to_dhis2)
  fetch_and_solve.call
  invoicing_request.invoices = Orbf::RulesEngine::InvoicePrinter.new(fetch_and_solve.solver.variables, fetch_and_solve.solver.solution).print

  @exported_values = fetch_and_solve.exported_values

  render "new_invoice"
end

  def render_legacy_invoice(project, invoicing_request)

    pyramid = project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
    pyramid ||= Pyramid.from(project)
    @pyramid = pyramid

    @datacompound = project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    @datacompound ||= DataCompound.from(project)

    org_unit = pyramid.org_unit(invoicing_request.entity)
    @org_unit = org_unit

    render(:new) && return unless org_unit
    org_unit.pyramid ||= pyramid

    @org_unit_summaries = [
      org_unit.name,
      "parents : " + pyramid.org_unit_parents(org_unit.id).map(&:name).join(" > "),
      "groups : " + pyramid.org_unit_groups_of(org_unit).compact.map(&:name).join(", "),
      "date range : " + project.date_range(invoicing_request.year_quarter).map(&:to_s).join(", "),
      "periods : " + project.periods(invoicing_request.year_quarter).map(&:to_dhis2).join(", "),
      "facts : " + Invoicing::EntityBuilder.new.to_entity(org_unit).facts.map(&:to_s).join(", ")
    ]

    unless pyramid.belong_to_group(org_unit, project.entity_group.external_reference)
      flash[:failure] = "Warn this entity is not in the contracted entity group : #{project.entity_group.name}."
      flash[:failure] += "Only simulation will work. Update the group and trigger a dhis2 snaphots."
    end

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

    begin
      invoicing_request.invoices = InvoicesForEntitiesWorker.new.perform(
        project.project_anchor_id,
        invoicing_request.year,
        invoicing_request.quarter,
        [org_unit.id],
        options
      )[org_unit.id]

      invoicing_request.invoices = invoicing_request.invoices.sort_by(&:date)
    rescue Rules::SolvingError => e
      log(e)
      flash[:alert] = "Failed to simulate invoice : #{e.class.name} #{e.message[0..100]} : <br>#{e.facts_and_rules.map { |k, v| [k, v].join(' : ') }.join(' <br>')}".html_safe
    rescue => e
      log(e)
      flash[:alert] = "Failed to simulate invoice : #{e.class.name} #{e.message[0..100]}"
    end
    render :new
  end

  def log(exception)
    Rails.logger.info " #{exception.message} : \n#{exception.backtrace.join("\n")}"
  end

  def invoice_params
    params.require(:invoicing_request)
          .permit(:entity,
                  :year,
                  :quarter,
                  :mock_values,
                :legacy_engine)
  end
end
