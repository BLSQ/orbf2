# frozen_string_literal: true

class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request, :indexed_project
  helper_method :invoicing_request
  helper_method :indexed_project

  def new
    project = current_project(project_scope: :fully_loaded) if params["calculate"]
    @invoicing_request = InvoicingRequest.new(
      project:        current_project,
      year:           params[:year] || current_quarter.split("Q")[0],
      quarter:        params[:quarter] || current_quarter.split("Q")[1],
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

  def current_quarter
    current_project.calendar.periods(current_project.calendar.from_iso(Date.today).strftime("%Y%m"),"quarterly").last
  end

  def render_invoice(project, invoicing_request)
    if params[:push_to_dhis2] && invoicing_request.entity

      dhis2_period = invoicing_request.year_quarter.to_dhis2

      invoicing_job = project.project_anchor.invoicing_jobs.find_or_initialize_by(
        project_anchor_id: project.project_anchor.id,
        dhis2_period:      dhis2_period,
        orgunit_ref:       invoicing_request.entity
      )

      job_id = InvoiceForProjectAnchorWorker.perform_async(
        project.project_anchor_id,
        invoicing_request.year,
        invoicing_request.quarter,
        [invoicing_request.entity]
      )

      invoicing_job.update(
        user_ref:        nil,
        status:          "enqueued",
        sidekiq_job_ref: job_id
      )
      flash[:alert] = "Worker scheduled for #{invoicing_request.entity} : #{invoicing_request.year_quarter.to_dhis2}"
      render(:new)
      return
    end

    render_new_invoice(project, invoicing_request)
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
      invoicing_request.entity,
      @invoice_entity.fetch_and_solve.contract_service,
      invoicing_request.period
    ).call

    add_contract_warning_if_non_contracted(invoicing_request, project)

    render "new_invoice"
  rescue StandardError => e
    @exception = e
    puts "An error occured during simulation #{e.class.name} #{e.message}" + e.backtrace.join("\n")
    flash[:failure] = "An error occured during simulation #{e.class.name} #{e.message[0..100]}"
    render "new_invoice"
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

    last_change = PaperTrail::Version.where(project_id: current_project).maximum("created_at")
    if job.processed_after?(time_stamp: last_change) && force != "strong"
      [false, "This job was recently processed: #{job.processed_at}, you can force a regeneration by checking the checkbox"]
    else
      [true]
    end
  end
end
