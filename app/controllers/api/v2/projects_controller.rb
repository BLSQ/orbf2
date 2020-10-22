# frozen_string_literal: true

module Api
  module V2
    class ProjectsController < BaseController
      def show
        options = {}
        project = nil
        if params[:profile] == "full"
          options[:include] = default_relationships
          project = current_project_anchor.projects.fully_loaded.find(current_project_anchor.project.id)
        else
          project = current_project_anchor.project
        end
        render json: serializer_class.new(project, options).serialized_json
      end

      private

      def default_relationships
        %i[
          compounds
          sets
          sets.topics
          sets.org_unit_groups
          sets.org_unit_group_sets
          sets.topics.input_mappings
          compounds.formulas
          compounds.sets
          compounds.formulas.formula_mappings
        ] + default_sets_relationships

      end

      def default_sets_relationships
        %w[topic set zone_topic zone multi_entities].flat_map do |scope|
          [
            "sets",
            "sets.#{scope}_decision_tables",
            "sets.#{scope}_formulas",
            "sets.#{scope}_formulas.formula_mappings",
            "sets.#{scope}_formulas.formula_mappings.external_ref"
          ].map(&:to_sym)
        end
      end

      def serializer_class
        ::V2::ProjectAnchorSerializer
      end
    end
  end
end
