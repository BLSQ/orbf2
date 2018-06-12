module Api
  class InvoicesController < Api::ApplicationController
    def create
      project_anchor = current_project_anchor
      pe = Periods.from_dhis2_period(params[:pe])

      InvoiceForProjectAnchorWorker.perform_async(
        project_anchor.id,
        pe.year,
        pe.to_quarter.quarter,
        [params[:ou]]
      )

      render json: { project_anchor: project_anchor.id }
    end
  end
end
