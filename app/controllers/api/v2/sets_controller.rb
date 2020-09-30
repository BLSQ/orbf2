# frozen_string_literal: true

module Api
  module V2
    class SetsController < BaseController

      def index
        packages = current_project_anchor.project.packages
        options = {}
        options[:include] = default_relationships

        render json: serializer_class.new(packages, options).serialized_json
      end

      def show
        package = current_project_anchor.project.packages.includes(Project::PACKAGE_INCLUDES).find(params[:id])

        options = {
          params: { with_sim_org_unit: true }
        }

        options[:include] = default_relationships + detailed_relationships
        render json: serializer_class.new(package, options).serialized_json
      end

      private

      def default_relationships
        %i[topics inputs org_unit_groups org_unit_group_sets]
      end

      def detailed_relationships
        %i[
          topics.input_mappings
          topic_formulas
          topic_formulas.formula_mappings
          topic_formulas.formula_mappings.external_ref
          set_formulas
          set_formulas.formula_mappings
          zone_topic_formulas
          zone_topic_formulas.formula_mappings
          zone_formulas
          zone_formulas.formula_mappings
          multi_entities_formulas
          multi_entities_formulas.formula_mappings
        ]
      end

      def serializer_class
        ::V2::PackageSerializer
      end
    end
  end
end
