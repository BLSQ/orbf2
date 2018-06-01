module Api
  class InvoicesController < Api::Base
    def create

      project_anchor = current_project_anchor
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
