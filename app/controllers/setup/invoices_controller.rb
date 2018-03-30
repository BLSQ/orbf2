require "natural_sort"

class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request
  helper_method :invoicing_request

  def new
    project = current_project(project_scope: :fully_loaded) if params["calculate"]
    @invoicing_request = InvoicingRequest.new(
      project:       current_project,
      year:          params[:year] || Date.today.to_date.year,
      quarter:       params[:quarter] || (Date.today.to_date.month / 4) + 1,
      entity:        params[:entity],
      legacy_engine: current_project.new_engine? ? false : true
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
    if params[:push_to_dhis2] && invoicing_request.entity
      InvoiceForProjectAnchorWorker.perform_async(
        project.project_anchor_id,
        invoicing_request.year,
        invoicing_request.quarter,
        [invoicing_request.entity]
      )
      flash[:alert] = "Worker scheduled for #{invoicing_request.entity} : #{invoicing_request.year_quarter.to_dhis2}"
      render(:new)
      return
    end

    if invoicing_request.legacy_engine?
      render_legacy_invoice(project, invoicing_request)
    else
      render_new_invoice(project, invoicing_request)
    end
  end

  def render_new_invoice(project, invoicing_request)
    options = Invoicing::InvoicingOptions.new(
      publish_to_dhis2:       false,
      force_project_id:       params[:simulate_draft] ? project.id : nil,
      allow_fresh_dhis2_data: params[:simulate_draft]
    )

    @invoice_entity = Invoicing::InvoiceEntity.new(project.project_anchor, invoicing_request, options)
    @invoice_entity.call
    Invoicing::MapToInvoices.new(invoicing_request, @invoice_entity.fetch_and_solve.solver).call

    @dhis2_export_values = @invoice_entity.fetch_and_solve.exported_values
    @dhis2_input_values = @invoice_entity.fetch_and_solve.dhis2_values
    @pyramid = @invoice_entity.pyramid
    @data_compound = @invoice_entity.data_compound

    activity_mappings

    @org_unit_summaries = Invoicing::EntitySignalitic.new(
      @pyramid,
      invoicing_request.entity
    ).call

    render "new_invoice"
  rescue StandardError => e
    flash[:failure] = "An error occured during simulation #{e.class.name} #{e.message[0..100]}"
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
    rescue StandardError => e
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

  # to allow display input dhis2 data elements
  def activity_mappings
    @activity_mappings = @invoice_entity.orbf_project
                                        .packages
                                        .each_with_object({}) do |package, activity_mappings|
      package.activities.each do |activity|
        activity.activity_states.each do |activity_state|
          activity_mappings[[activity.activity_code, activity_state.state]] = activity_state
        end
      end
    end
  end
end
