module Api
  class OrgunitHistoryController < Api::Base
    def index
      project_anchor = current_project_anchor
      group_params = Groups::GroupParams.new(project_anchor, params)
      groups = { organisationUnits: Groups::ListHistory.new(group_params).call }
      render json: Case.deep_change(groups, :camelize).to_json
    end
  end
end
