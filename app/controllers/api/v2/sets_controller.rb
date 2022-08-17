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

      def update
        package = current_project_anchor.project.packages.includes(Project::PACKAGE_INCLUDES).find(params[:id])

        package.update(set_attributes)

        options = {
          params: { with_sim_org_unit: true }
        }

        package.save!

        options[:include] = default_relationships + detailed_relationships
        render json: serializer_class.new(package, options).serialized_json
      end

      def create
        package = nil
        Package.transaction do
          package = current_project_anchor.project.packages.create!(set_attributes)

          entity_groups = nil
          if meta_set_attributes[:main_entity_groups].any? || meta_set_attributes[:target_entity_groups].any?
            entity_groups = package.create_package_entity_groups(
              meta_set_attributes[:main_entity_groups],
              meta_set_attributes[:target_entity_groups]
            )
          end

          if package.save! && entity_groups.present?
            package.package_entity_groups.create(entity_groups)
            SynchroniseDegDsWorker.perform_async(current_project_anchor.id)
          end
        end

        options = {
          params: { with_sim_org_unit: true }
        }

        options[:include] = default_relationships + detailed_relationships
        render json: serializer_class.new(package, options).serialized_json
      end

      private

      def default_relationships
        %i[topics inputs project_inputs project_activities org_unit_groups org_unit_group_sets]
      end

      def detailed_relationships
        %i[topics.input_mappings] + detailed_formulas_relationships
      end

      def detailed_formulas_relationships
        %w[topic set zone_topic zone multi_entities].flat_map do |scope|
          [
            "#{scope}_decision_tables",
            "#{scope}_formulas",
            "#{scope}_formulas.formula_mappings",
            "#{scope}_formulas.formula_mappings.external_ref"
          ].map(&:to_sym)
        end
      end

      def set_params
        params.require(:data)
              .permit(attributes: [
                        :name,
                        :description,
                        :frequency,
                        :kind,
                        :dataElementGroupExtRef,
                        :includeMainOrgunit,
                        :ogsReference => [],
                        :loopOverComboExtId => [],
                        :inputs => [],
                        :topics => [],
                        :groupSetsExtRefs => [],
                        :mainEntityGroups => [],
                        :targetEntityGroups => []
                      ])
      end

      def set_attributes
        att = set_params[:attributes]
        {
          name:                       att[:name],
          description:                att[:description],
          frequency:                  att[:frequency],
          kind:                       att[:kind],
          ogs_reference:              att[:ogsReference],
          loop_over_combo_ext_id:     att[:loopOverComboExtId],
          activity_ids:               att[:topics] || [],
          groupsets_ext_refs:         att[:groupSetsExtRefs] || [],
          state_ids:                  att[:inputs] || [],
          include_main_orgunit:       att[:includeMainOrgunit],
          data_element_group_ext_ref: "todo"
        }
      end

      def meta_set_attributes
        att = set_params[:attributes]
        {
          main_entity_groups:   att[:mainEntityGroups] || [],
          target_entity_groups: att[:targetEntityGroups] || []
        }
      end

      def serializer_class
        ::V2::PackageSerializer
      end
    end
  end
end
