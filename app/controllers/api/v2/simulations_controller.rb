# frozen_string_literal: true

module Api::V2
  class SimulationsController < BaseController

    # Get a list of all simulations
    def index
      project_anchor = current_project_anchor
      jobs = project_anchor.invoicing_simulation_jobs

      render json: serializer_class.new(jobs).serialized_json
    end

    # Single simulation based on `:id`
    def show
      project_anchor = current_project_anchor
      job = project_anchor.invoicing_simulation_jobs.find(params[:id])

      render json: serializer_class.new(job).serialized_json
    end

    # Single simulation based on supplying:
    #
    #      `orgUnit` - organisation unit reference (string)
    #      `periods` - comma separated list of periods (currently only first will be used)
    #
    def query_based_show
      project_anchor = current_project_anchor
      if valid_query_params?(params)
        org_unit = params[:orgUnit]
        period = params[:periods].split(",").first

        job = project_anchor.invoicing_simulation_jobs.where(
          dhis2_period: period,
          orgunit_ref: org_unit
        ).first
        render json: serializer_class.new(job).serialized_json
      else
        return bad_request("Missing required parameters: orgUnit and periods")
      end
    end

    def create
      invoicing_request = InvoicingRequest.new(
        entity:         simulation_params.fetch(:orgUnit),
        year:           simulation_params.fetch(:year),
        quarter:        simulation_params.fetch(:quarter),
        mock_values:    simulation_params[:mock_values],
        engine_version: simulation_params[:engine_version],
        with_details:   simulation_params[:with_details],
      )
      job = project.project_anchor.invoicing_simulation_jobs.where(
        dhis2_period: invoicing_request.period,
        orgunit_ref:  invoicing_request.entity
      ).first_or_create(
        dhis2_period: invoicing_request.period,
        orgunit_ref:  invoicing_request.entity
      )
      should_enqueue, reason = enqueue_simulation_job(job, params[:force])

      if should_enqueue
        # Ensure status of job back is enqueued
        job.enqueued!
        args = invoicing_request.to_h.merge(simulate_draft: params[:simulate_draft])
        InvoiceSimulationWorker.perform_async(*args.values)
      end
      options = {
        was_enqueued: should_enqueue,
        reason_for_not_enqueing: reason
      }
      render json: serializer_class.new(job).serialized_json
    rescue KeyError => e
      missing = %w(orgUnit year quarter).inject([]) do |r, w|
        value = simulation_params[w.to_sym]
        r << word unless value.present?
        r
      end
      return bad_request("Missing these required parameters: #{missing.join(", ")}")
    end

    private

    def serializer_class
      ::V2::InvoicingJobSerializer
    end

    def simulation_params
      params.require(:data)
        .permit(:type,
                attributes: [
                  :orgUnit,
                  :year,
                  :quarter,
                  :mock_values,
                  :engine_version,
                  :with_details
                ])
    end

    def valid_query_params?(query_params)
      !!(params[:orgUnit] && params[:periods])
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
end
