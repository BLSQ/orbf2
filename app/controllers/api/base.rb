
class Api::Base < ActionController::Base
  before_action :set_permissive_cors_headers

  private

  def current_project_anchor
    @current_project_anchor || ProjectAnchor.find_by!(token: params.fetch(:token))
  end

  def set_permissive_cors_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, OPTIONS"
    headers["Access-Control-Request-Method"] = "*"
    headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Authorization"
  end
end
