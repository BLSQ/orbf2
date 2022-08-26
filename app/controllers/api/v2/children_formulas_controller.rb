# frozen_string_literal: true

module Api
  module V2
    class ChildrenFormulasController < FormulasController
      def find_rule 
        current_project_anchor.project.packages.find(params[:set_id]).multi_entities_rule
      end
    end
  end
end