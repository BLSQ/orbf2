# frozen_string_literal: true

module Api
  module V2
    class TopicFormulasController < FormulasController
      def find_formula
        package = current_project_anchor.project.packages.find(params[:set_id])
        formula = package.activity_rule.formulas.find(params[:id])
        formula
      end

      def detailed_relationships
        # %i[topics.input_mappings] + detailed_formulas_relationships
        %i[used_formulas]
      end
    end
  end
end