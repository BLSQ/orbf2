# frozen_string_literal: true

module Api
  module V2
    class ZoneFormulasController < FormulasController
      def find_rule
        package = current_project_anchor.project.packages.find(params[:set_id])
        rule = package.zone_rule
        if rule.nil?
          rule = package.rules.create!(kind: :zone, name: package.name + " - zone")
        end
        rule
      end
    end
  end
end