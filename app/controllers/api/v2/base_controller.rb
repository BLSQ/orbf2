module Api::V2
  class ApiError < StandardError; end
  class UnauthorizedAccess < ApiError; end

  class BaseController < ActionController::API
    before_action :set_permissive_cors_headers
    before_action :check_token!

    rescue_from ActiveRecord::RecordNotFound do |exception|
      error = { status: "404", message: "Not Found" }

      render status: :not_found, json: { errors: [error] }
    end

    rescue_from UnauthorizedAccess do |exception|
      error = { status: "401", message: "Unauthorized" }

      render status: :unauthorized, json: { errors: [error] }
    end

    def options
      render json: {}
    end

    private

    def check_token!
      if token = request.headers["X-Token"] || params[:token]
        @current_project_anchor ||= ProjectAnchor.find_by!(token: token)
      else
        raise UnauthorizedAccess, "Unauthorized"
      end

    rescue ActiveRecord::RecordNotFound
      raise UnauthorizedAccess, "Unauthorized"
    end

    def bad_request(message, source = nil)
      Rails.logger.warn([message, Array.wrap(source).join("\n")].join("\n"))
      error_data =                           {
        status: :bad_request,
        detail: message,
      }
      error_data.merge!(source: source) if source
      render status: :bad_request, json: { errors: [error_data] }
    end

    def current_project_anchor
      return @current_project_anchor if @current_project_anchor

      check_token!
      @current_project_anchor
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
