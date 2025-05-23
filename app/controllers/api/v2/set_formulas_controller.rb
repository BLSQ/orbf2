# frozen_string_literal: true

module Api
  module V2
    class SetFormulasController < FormulasController
      def find_rule
        package = current_project_anchor.project.packages.find(params[:set_id])
        rule = package.package_rule
        if rule.nil?
          rule = package.rules.create!(kind: :package, name: package.name + " - package")
        end
        rule
      end      
    end
  end
end