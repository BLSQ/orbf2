# frozen_string_literal: true

module Api
  module V1
    class InvoicingJobsController < ApplicationController
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from ArgumentError, with: :bad_request

      def index
        project_anchor = current_project_anchor

        render json: InvoicingJobSerializer.new(find_jobs(project_anchor), {}).serialized_json
      end

      def create
        index
      end

      private

      def find_jobs(project_anchor)
        period = params.fetch(:period)
        # if monthly then turn it into quarterly
        if Periods.detect(period) == Periods::MONTHLY
          period = Periods.from_dhis2_period(period)
          period = period.to_quarter.to_dhis2
        end
        jobs = project_anchor.invoicing_jobs
                             .where(dhis2_period: period)
        jobs = jobs.where(orgunit_ref: params[:orgUnitIds].split(",")) if params[:orgUnitIds]
        jobs = jobs.where(status: params[:status].split(",")) if params[:status]
        jobs.last(1000)
      end
    end
  end
end
