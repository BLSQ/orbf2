# frozen_string_literal: true

module Api
  module V2
    class FormulasController < BaseController
      before_action :check_whodunnit!

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

        updated_formulas = []
        if formula_attributes[:code] != formula.code
          updated_formulas = formula.rule.refactor(formula, formula_attributes[:code])
        end

        formula.transaction do
          formula.update!(formula_attributes)
          updated_formulas.each do |f|
            f.save(validate: false) # skipping validation because not aware of formula_attributes code change in other formulas
          end
          rule = formula.rule
          rule.reload
          rule.save!
        end

        options[:include] = default_relationships + detailed_relationships
        render json: serializer_class.new(formula, options).serialized_json
      end

      def create
        formula = nil
        Formula.transaction do
          formula = create_formula
          rule = formula.rule
          formula.reload
          rule.reload
          rule.save!
        end

        options = {
          params: { with_edition_details: true }
        }
        render json: serializer_class.new(formula, options).serialized_json
      end

      def destroy
        formula = find_formula
        options = {
          params: { with_edition_details: true }
        }

        formula.destroy! unless formula.used_by_formulas.any?

        render json: serializer_class.new(formula, options).serialized_json
      end

      private

      def find_formula
        find_rule.formulas.find(params[:id])
      end

      def create_formula
        find_rule.formulas.create!(formula_attributes)
      end

      def default_relationships
        # %i[topics inputs org_unit_groups org_unit_group_sets]
        []
      end

      def detailed_relationships
        %i[used_formulas used_by_formulas]
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
                        code
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
          code:                    att[:code],
          description:             att[:description],
          short_name:              att[:shortName],
          expression:              att[:expression],
          frequency:               att[:frequency],
          exportable_formula_code: att[:exportableFormulaCode]
        }
      end
    end
  end
end
