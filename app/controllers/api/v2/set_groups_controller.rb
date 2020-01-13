# frozen_string_literal: true

module Api
  module V2
    class SetGroupsController < BaseController
      def index
        payment_rules = current_project_anchor.project.payment_rules
        options = {}
        options[:include] = [:formulas]

        render json: serializer_class.new(payment_rules, options).serialized_json
      end

      def show
        package = current_project_anchor.project.packages.find(params[:id])

        render json: serializer_class.new(package).serialized_json
      end

      private

      def serializer_class
        ::V2::PaymentRuleSerializer
      end
    end
  end
end
