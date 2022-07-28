# frozen_string_literal: true

module Api
  module V2
    class CompoundFormulasController < FormulasController
      def find_rule
        current_project_anchor.project.payment_rules.find(params[:compound_id]).rule
      end
    end
  end
end