# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ::ActionController::Base
      before_action :set_permissive_cors_headers

      def options
        render json: {}
      end

      private

      def bad_request(error)
        Rails.logger.warn([error.message, error.backtrace.join("\n")].join("\n"))
        render status: :bad_request, json: { status: "KO", message: error.message }
      end

      def current_project_anchor
        token = request.headers["X-Token"] || params.fetch(:token)
        @current_project_anchor || ProjectAnchor.find_by!(token: token)
      end

      ALL = "*"
      ALLOW_HEADERS = "Origin, X-Requested-With, Content-Type, Accept, Authorization, X-token, X-Dhis2UserId"

      def set_permissive_cors_headers
        headers["Access-Control-Allow-Origin"] = ALL
        headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, PATCH, OPTIONS"
        headers["Access-Control-Request-Method"] = ALL
        headers["Access-Control-Allow-Headers"] = ALLOW_HEADERS
      end
    end
  end
end
