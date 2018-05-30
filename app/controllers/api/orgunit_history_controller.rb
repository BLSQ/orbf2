module Api
  class OrgunitHistoryController < ActionController::Base
    def index
      project_anchor = ProjectAnchor.find_by(token: params.fetch(:token))
      group_params = Groups::GroupParams.new(project_anchor, params)
      groups = { organisationUnits: Groups::ListHistory.new(group_params).call }
      render json: Case.deep_change(groups, :camelize).to_json
    end
  end
end
