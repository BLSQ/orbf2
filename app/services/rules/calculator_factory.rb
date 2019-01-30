require "dentaku"
require "dentaku/calculator"

module Rules
  class CalculatorFactory
    def new_calculator
      Orbf::RulesEngine::LegacyCalculatorFactory.build({})
    end
  end
end
