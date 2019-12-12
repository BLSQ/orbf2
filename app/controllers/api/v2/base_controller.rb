module Api::V2
  class BaseController < ActionController::API
    before_action :set_permissive_cors_headers

    rescue_from ActiveRecord::RecordNotFound do |exception|
      render status: :not_found, json: { errors: [
                                           {
                                             status: "404",
                                             message: "Not Found"
                                           }
                                         ]}
    end

    private

    def bad_request(e)
      Rails.logger.warn([e.message, e.backtrace.join("\n")].join("\n"))
      render status: :bad_request, json: { errors: [
                                             {
                                               status: :bad_request,
                                               detail: e.message,
                                               source: e.backtrace.join("\n")
                                             }
                                           ]}
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
