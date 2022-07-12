# frozen_string_literal: true

module Api
  module V2
    class SetFormulasController < FormulasController
      def find_formula
        package = current_project_anchor.project.packages.find(params[:set_id])
        formula = package.package_rule.formulas.find(params[:id])
        formula
      end
    end
  end
end