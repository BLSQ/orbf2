# frozen_string_literal: true

module Api::V1
  class SimulationsController < ApplicationController
    # Currently only in use by the asynchronous simulation page, will
    # display information about the simulation job.

    rescue_from ActiveRecord::RecordNotFound do |exception|
      render status: :not_found, json: { status: "404", message: "Not Found" }
    end

    def index
      project_anchor = current_project_anchor

      render json: InvoicingJobSerializer.new(project_anchor.invoicing_simulation_jobs).serialized_json
    end

    def show
      project_anchor = current_project_anchor

      job = project_anchor.invoicing_simulation_jobs.find(params[:id])

      render json: InvoicingJobSerializer.new(job).serialized_json
    end
  end
end
