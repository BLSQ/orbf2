# frozen_string_literal: true

module Api
  module V2
    class TopicFormulasController < FormulasController
      def find_rule
        package = current_project_anchor.project.packages.find(params[:set_id])
        rule = package.activity_rule
        if rule.nil?
          rule = package.rules.create!(kind: :activity, name: package.name + " - activity")
        end
        rule
      end
    end
  end
end
