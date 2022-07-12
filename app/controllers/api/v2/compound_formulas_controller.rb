# frozen_string_literal: true

module Api
  module V2
    class CompoundFormulasController < FormulasController
      def find_formula
        payment_rule = current_project_anchor.project.payment_rules.find(params[:compound_id])
        formula = payment_rule.rule.formulas.find(params[:id])
        formula
      end
    end
  end
end