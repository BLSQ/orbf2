# frozen_string_literal: true

module Api
  module V2
    class CalculationsController < BaseController
      def show
        evaluate
      end

      def create
        evaluate
      end

      private

      def calculations_params
        params.permit("values" => {})
      end

      def evaluate
        calculator = Orbf::RulesEngine::CalculatorFactory.build(3)
        expression = params[:expression]
        calculations_params[:values].each do |key, value|
          expression = expression.gsub("%{#{key}}", value)
        end
        problem = { "expression" => expression }
        problem = problem.merge(calculations_params[:values])
        begin
          solution = calculator.solve(problem)
          result = { status: "ok", expression: params[:expression], values: calculations_params[:values], result: solution["expression"].to_s }
        rescue Hesabu::Error => e
          result = { status: "error", expression: params[:expression], values: calculations_params[:values], error: e.message }
        end

        render json: result.to_json
      end
    end
  end
end