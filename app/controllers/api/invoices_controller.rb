module Api
  class InvoicesController < ActionController::Base
    protect_from_forgery with: :exception

    def create
      project_anchor = ProjectAnchor.find_by(token: params[:token])

      pe = Periods.from_dhis2_period(params[:pe])
      org_unit_id = params[:ou]

      InvoiceForProjectAnchorWorker.perform_async(
        project_anchor.id,
        pe.year,
        pe.to_quarter.quarter,
        [org_unit_id]
      )

      render json: { project_anchor: project_anchor.id }
    end
  end
end
