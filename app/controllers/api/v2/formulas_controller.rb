# frozen_string_literal: true

module Api
  module V2
    class FormulasController < BaseController
      # def index
      #   packages = current_project_anchor.project.packages
      #   options = {}
      #   options[:include] = default_relationships

      #   render json: serializer_class.new(packages, options).serialized_json
      # end

      def show
        formula = find_formula
        options = {
          params: { with_edition_details: true }
        }

        options[:include] = default_relationships + detailed_relationships
        render json: serializer_class.new(formula, options).serialized_json
      end

      def update
        formula = find_formula
        options = {
          params: { with_edition_details: true }
        }

        
        formula.update!(formula_attributes)

        options[:include] = default_relationships + detailed_relationships
        render json: serializer_class.new(formula, options).serialized_json
      end

      private

      def default_relationships
        # %i[topics inputs org_unit_groups org_unit_group_sets]
        []
      end

      def detailed_relationships
        # %i[topics.input_mappings] + detailed_formulas_relationships
        []
      end

      def detailed_formulas_relationships
        []
      end

      def serializer_class
        ::V2::FormulaSerializer
      end

      def formula_params
        params.require(:data)
              .permit(:type,
                      attributes: %i[
                        description
                        exportableFormulaCode
                        expression
                        frequency
                        shortName
                      ])
      end
  
      def formula_attributes
        att = formula_params[:attributes]
        {
          description:                   att[:description],
          short_name:                    att[:shortName],
          expression:                    att[:expression],
          frequency:                     att[:frequency],
          exportable_formula_code:       att[:exportableFormulaCode]
        }
      end
    end
  end
end
