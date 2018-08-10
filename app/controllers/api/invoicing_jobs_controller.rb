# frozen_string_literal: true

module Api
  class InvoicingJobsController < Api::ApplicationController
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from ArgumentError, with: :bad_request

    def index
      project_anchor = current_project_anchor
      period = Periods.from_dhis2_period(params.fetch(:pe))

      render json: project_anchor.invoicing_jobs.where(dhis2_period: period.to_quarter.to_dhis2).last(100)
    end

    private

    def bad_request(e)
      Rails.logger.warn([e.message, e.backtrace.join("\n")].join("\n"))
      render status: :bad_request, json: { status: "KO", message: e.message }
    end
  end
end
