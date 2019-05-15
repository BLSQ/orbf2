# frozen_string_literal: true

class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request, :indexed_project
  helper_method :invoicing_request
  helper_method :indexed_project

  def new
    project = current_project(project_scope: :fully_loaded) if params["calculate"]
    @invoicing_request = InvoicingRequest.new(
      project:        current_project,
      year:           params[:year] || Date.today.to_date.year,
      quarter:        params[:quarter] || (Date.today.to_date.month / 4) + 1,
      entity:         params[:entity],
      with_details:   params[:with_details] || false,
      engine_version: current_project.engine_version
    )
    if params["calculate"]
      render_invoice(project, invoicing_request)
      return
    end
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))
    @org_unit_limiter = OrgUnitLimiter.from_params(params)

    if @invoicing_request.valid?
      render_invoice(project, invoicing_request)
    else
      render :new
    end
  end

  class OrgUnitLimiter
    # Small PORO to help with the `selected_org_units` filter, a user
    # can selectively choose to limit the results to certain org
    # units.
    def self.from_params(incoming)
      org_unit_ids = (incoming[:selected_org_units] || "").split(",").map(&:strip)
      new(org_unit_ids)
    end

    def active?
      org_unit_ids.count > 0
    end

    def initialize(selected_org_units)
      @selected_org_units = selected_org_units
    end

    def has_org_unit?(org_unit_id)
      org_unit_ids.include?(org_unit_id)
    end

    def org_unit_ids
      @selected_org_units || []
    end

    def to_param
      return {} unless active?

      { selected_org_units: org_unit_ids.join(",") }
    end
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
      if params[:simulate_async] && Flipper[:use_async_simulation].enabled?(current_user)

        job = project.project_anchor.invoicing_simulation_jobs.where(
          dhis2_period: invoicing_request.period,
          orgunit_ref:  invoicing_request.entity
        ).first_or_create(
          dhis2_period: invoicing_request.period,
          orgunit_ref:  invoicing_request.entity
        )
        shouldEnqueue, reason = enqueue_simulation_job(job, params[:force])
        if shouldEnqueue
          args = invoicing_request.to_h.merge(simulate_draft: params[:simulate_draft])
          InvoiceSimulationWorker.perform_async(*args.values)
        else
          @not_enqueued_reason = reason
        end

        project.project_anchor.update_token_if_needed
        @simulation_job_url = api_simulation_path(job, token: project.project_anchor.token)
        return render "async_invoice"
      else
        render_new_invoice(project, invoicing_request)
      end
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
    @indexed_project = Invoicing::IndexedProject.new(project, @invoice_entity.orbf_project)
    Invoicing::MapToInvoices.new(invoicing_request, @invoice_entity.fetch_and_solve.solver).call

    @dhis2_export_values = @invoice_entity.fetch_and_solve.exported_values
    @dhis2_input_values = @invoice_entity.fetch_and_solve.dhis2_values
    @pyramid = @invoice_entity.pyramid
    @data_compound = @invoice_entity.data_compound

    @org_unit_summaries = Invoicing::EntitySignalitic.new(
      @pyramid,
      invoicing_request.entity
    ).call

    add_contract_warning_if_non_contracted(invoicing_request, project)

    render "new_invoice"
  rescue StandardError => e
    @exception = e
    puts "An error occured during simulation #{e.class.name} #{e.message}" + e.backtrace.join("\n")
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
      mock_values:   invoicing_request.mock_values?
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
      @exception = e
      log(e)
      flash[:alert] = "Failed to simulate invoice : #{e.class.name} #{e.message[0..100]} : <br>#{e.facts_and_rules.map { |k, v| [k, v].join(' : ') }.join(' <br>')}".html_safe
    rescue StandardError => e
      @exception = e
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
                  :engine_version,
                  :with_details)
  end

  def add_contract_warning_if_non_contracted(invoicing_request, project)
    return if contracted?(invoicing_request, project)

    flash[:failure] = non_contracted_orgunit_message(project)
  end

  def contracted?(invoicing_request, project)
    org_unit = @pyramid.org_unit(invoicing_request.entity)
    org_unit.group_ext_ids.include?(project.entity_group.external_reference)
  end

  def non_contracted_orgunit_message(project)
    "Entity is not in the contracted entity group : #{project.entity_group.name}." \
     " (Snaphots last updated on #{project.project_anchor.updated_at.to_date})." \
     " Only simulation will work. Update the group and trigger a dhis2 snaphots." \
     " Note that it will only fix this issue for current or futur periods."
  end

  def enqueue_simulation_job(job, force)
    # New jobs always need processing
    return true if job.id_previously_changed?
    return [false, "This job is still processing"] if job.alive?

    # TODO: Use papertail for a more accurate guess if simulation is outdated.
    if job.processed_after?(time_stamp: 10.minutes.ago) && force != "strong"
      [false, "This job was recently processed: #{job.processed_at}, you can force a regeneration with `?force=strong`"]
    else
      [true]
    end
  end
end
