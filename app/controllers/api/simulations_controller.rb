# frozen_string_literal: true

class Api::SimulationsController < Api::ApplicationController

  def show
    project_anchor = current_project_anchor

    job = project_anchor.invoicing_simulation_jobs.find(params[:id])

    render json: InvoicingJobSerializer.new(job).serialized_json
  end
end
