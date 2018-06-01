module Api
  class Base < ActionController::Base
    before_action :set_permissive_cors_headers

    private

    def current_project_anchor
      @current_project_anchor || ProjectAnchor.find_by!(token: params.fetch(:token))
    end

    ALL = "*".freeze
    ALLOW_HEADERS = "Origin, X-Requested-With, Content-Type, Accept, Authorization".freeze

    def set_permissive_cors_headers
      headers["Access-Control-Allow-Origin"] = ALL
      headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, OPTIONS"
      headers["Access-Control-Request-Method"] = ALL
      headers["Access-Control-Allow-Headers"] = ALLOW_HEADERS
    end
  end
end
