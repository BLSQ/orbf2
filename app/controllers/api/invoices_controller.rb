# frozen_string_literal: true

module Api
  class InvoicesController < Api::ApplicationController
    def create
      project_anchor = current_project_anchor
      pe = Periods.from_dhis2_period(params[:pe])

      job_id = InvoiceForProjectAnchorWorker.perform_async(
        project_anchor.id,
        pe.year,
        pe.to_quarter.quarter,
        [params[:ou]]
      )

      invoicing_job = project_anchor.invoicing_jobs.find_or_initialize_by(
        project_anchor_id: project_anchor.id,
        dhis2_period:      pe.to_quarter.to_dhis2,
        orgunit_ref:       params[:ou]
      )

      invoicing_job.update(
        user_ref:        params[:dhis2UserId],
        status:          "enqueued",
        sidekiq_job_ref: job_id
      )

      render json: { project_anchor: project_anchor.id }
    end
  end
end
