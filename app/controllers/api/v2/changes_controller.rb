# frozen_string_literal: true

module Api
  module V2
    class ChangesController < BaseController
      def index
        # byebug
        changes = project.project_anchor.program.versions.order("id DESC").limit(100)
        # byebug
        options = {}

        render json: serializer_class.new(changes, options).serialized_json
      end

      private

      def project
        current_project_anchor.project
      end

      def serializer_class
        ::V2::ChangeSerializer
      end
    end
  end
end
