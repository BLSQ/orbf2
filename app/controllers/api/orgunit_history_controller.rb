module Api
  class OrgunitHistoryController < Api::Base
    def index
      project_anchor = current_project_anchor
      group_params = Groups::GroupParams.new(project_anchor, params)
      groups = { organisationUnits: Groups::ListHistory.new(group_params).call }
      render json: Case.deep_change(groups, :camelize).to_json
    end

    def apply

      # TODO
      #  - reject or ignore current month and futur
      #  - compare reference period with db, tell that the data is no more in the same state
      #  - check what paper trail says about the changes
      project_anchor = current_project_anchor
      update_params = Groups::UpdateParams.new(project_anchor, params)
      Groups::UpdateHistory.new(update_params).call
      render json: { status: "OK" }
    end
  end
end
