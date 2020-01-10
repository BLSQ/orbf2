# frozen_string_literal: true

module Api
  module V2
    class SetsController < BaseController
      def index
        packages = current_project_anchor.project.packages
        options = {}
        options[:include] = [:topics, :inputs, :org_unit_groups, :org_unit_group_sets]

        render json: serializer_class.new(packages, options).serialized_json
      end

      def show
        package = current_project_anchor.project.packages.find(params[:id])

        render json: serializer_class.new(package).serialized_json
      end

      private

      def serializer_class
        ::V2::PackageSerializer
      end
    end
  end
end
