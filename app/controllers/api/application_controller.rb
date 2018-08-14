module Api
  class ApplicationController < ::ActionController::Base
    before_action :set_permissive_cors_headers

    def options
      render json: {}
    end

    private

    def bad_request(e)
      Rails.logger.warn([e.message, e.backtrace.join("\n")].join("\n"))
      render status: :bad_request, json: { status: "KO", message: e.message }
    end

    def current_project_anchor
      token = request.headers["X-Token"] || params.fetch(:token)
      @current_project_anchor || ProjectAnchor.find_by!(token: token)
    end

    ALL = "*".freeze
    ALLOW_HEADERS = "Origin, X-Requested-With, Content-Type, Accept, Authorization, X-token".freeze

    def set_permissive_cors_headers
      headers["Access-Control-Allow-Origin"] = ALL
      headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, PATCH, OPTIONS"
      headers["Access-Control-Request-Method"] = ALL
      headers["Access-Control-Allow-Headers"] = ALLOW_HEADERS
    end
  end
end
