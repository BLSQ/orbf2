# frozen_string_literal: true

module Api
  module V2
    class CompoundsController < BaseController
      def index
        payment_rules = project.payment_rules
        options = {}
        options[:include] = default_relationships

        render json: serializer_class.new(payment_rules, options).serialized_json
      end

      def show
        payment_rule = project.payment_rules.find(params[:id])
        options = {}
        options[:include] = default_relationships + detailed_relationships

        render json: serializer_class.new(payment_rule, options).serialized_json
      end

      private

      def default_relationships
        %i[formulas sets]
      end

      def detailed_relationships
        %i[
          formulas.formula_mappings
        ]
      end

      def project
        current_project_anchor.project
      end

      def serializer_class
        ::V2::PaymentRuleSerializer
      end
    end
  end
end
