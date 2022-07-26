# frozen_string_literal: true

module Api
  module V2
    class TopicFormulasController < FormulasController
      def find_formula
        package = current_project_anchor.project.packages.find(params[:set_id])
        formula = package.activity_rule.formulas.find(params[:id])
        formula
      end

      def create_formula
        package = current_project_anchor.project.packages.find(params[:set_id])
        formula = package.activity_rule.formulas.create!(formula_attributes)
        formula
      end

      def detailed_relationships
        %i[used_formulas used_by_formulas]
      end
    end
  end
end