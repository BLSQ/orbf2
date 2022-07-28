# frozen_string_literal: true

module Api
  module V2
    class ZoneFormulasController < FormulasController
      def find_rule
        current_project_anchor.project.packages.find(params[:set_id]).zone_rule
      end
    end
  end
end