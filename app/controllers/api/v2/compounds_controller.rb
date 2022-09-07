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

      def new
        payment_rule = project.payment_rules.build(rule_attributes: { kind: "payment" })
        payment_rule.rule.formulas.build
        options = {}
        options[:include] = default_relationships
        render json: serializer_class.new(payment_rule, options).serialized_json
      end

      def create
        payment_rule = nil
        payment_rules_attributes = compound_attributes
        options = {}

        PaymentRule.transaction do
          payment_rule = project.payment_rules.create(payment_rules_attributes)
          payment_rule.save!
        end

        options[:include] = default_relationships
        render json: serializer_class.new(payment_rule, options).serialized_json
      end

      private

      def default_relationships
        %i[formulas sets project_sets rule]
      end

      def detailed_relationships
        %i[
          formulas.formula_mappings
        ]
      end

      def compound_params
        params.require(:data)
              .permit(attributes: [
                        :sets,
                        :frequency,
                        :name
                      ])
      end

      def compound_attributes
        att = compound_params[:attributes]
        {
          frequency:       att[:frequency],
          package_ids:     att[:sets] || [],
          rule_attributes: {
            name: att[:name],
            kind: "payment"
          }
        }
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
