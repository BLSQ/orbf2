# frozen_string_literal: true

module Api
  module V2
    class ZoneTopicFormulasController < FormulasController
      def find_rule
        package = current_project_anchor.project.packages.find(params[:set_id])
        rule = package.zone_activity_rule
        if rule.nil?
          rule = package.rules.create!(kind: :zone_activity, name: package.name + " - zone activity")
        end
        rule
      end
    end
  end
end