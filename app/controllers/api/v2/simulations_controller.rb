# frozen_string_literal: true

module Api::V2
  class SimulationsController < BaseController

    # Get a list of all simulations
    def index
      project_anchor = current_project_anchor
      jobs = project_anchor.invoicing_simulation_jobs

      render json: InvoicingJobSerializer.new(jobs).serialized_json
    end

    # Single simulation based on `:id`
    def show
      project_anchor = current_project_anchor
      job = project_anchor.invoicing_simulation_jobs.find(params[:id])

      render json: InvoicingJobSerializer.new(job).serialized_json
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
        render json: InvoicingJobSerializer.new(job).serialized_json
      else
        return bad_request("Missing required parameters: orgUnit and periods")
      end
    end

    private

    def valid_query_params?(query_params)
      !!(params[:orgUnit] && params[:periods])
    end

  end
end
