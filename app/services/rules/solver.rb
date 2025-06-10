# frozen_string_literal: true

require "dentaku"
require "dentaku/calculator"

module Rules
  class Solver
    attr_reader :calculator

    def initialize
      @calculator = CalculatorFactory.new.new_calculator
    end

    def solve!(message, facts_and_rules, debug = false)
      log "********** #{message} #{Time.new}\n#{JSON.pretty_generate(facts_and_rules)}\n" if debug
      #puts JSON.pretty_generate(facts_and_rules)
      begin
        solution = calculator.solve!(facts_and_rules)
      rescue TSort::Cyclic => cycle_error
        log JSON.pretty_generate(facts_and_rules)
        log cycle_error.message
        raise SolvingError.new("a cycle has been created : " + cycle_error.message, facts_and_rules),
              "Failed to solve this problem : a cycle exist between formulas: "\
              "#{message} : #{cycle_error.message}"
      rescue StandardError => e
        log JSON.pretty_generate(facts_and_rules)
        log e.message
        raise SolvingError.new(e.message, facts_and_rules),
              "Failed to solve this problem #{message} : #{e.message}"
      end
      log JSON.pretty_generate([solution]) if debug
      solution.with_indifferent_access
    end

    def validate_expression(formula)
      calculator.dependencies(
        Rules::ValuesMocker.mock_values(
          formula.expression,
          formula.rule.available_variables_for_values
        )
      )
    rescue KeyError => e
      formula.errors[:expression] << "#{e.message}. " \
        "Remove extra spaces or verify it's in the available variables"
    rescue StandardError => e
      Rails.logger.warn("FAILED to validate #{formula} : #{e.backtrace.join("\n")}")
      formula.errors[:expression] << e.message
    end

    def dependencies(formula)
      calculator.dependencies(
        Rules::ValuesMocker.mock_values(
          formula.expression,
          formula.rule.available_variables_for_values
        )
      )
    rescue StandardError => ignored
      []
    end

    def validate_formulas(rule)
      return if rule.formulas.empty?

      facts = {}.merge(rule.fake_facts)
      rule.formulas.each do |formula|
        facts[formula.code] = Rules::ValuesMocker.mock_values(
          formula.expression,
          rule.available_variables_for_values
        )
      end
      facts[:actictity_rule_name] = Solver.escape_string(rule.name)
      solve!("validate_all_formulas", facts)
    rescue Rules::SolvingError => e
      rule.errors[:formulas] << e.original_message
    rescue KeyError => e
      rule.errors[:formulas] << "#{e.message}. Remove extra spaces or verify it's in the available variables"
    rescue StandardError => e
      log(e.message)
      rule.errors[:formulas] << e.message
    end

    def self.escape_string(string)
      "'#{string.tr("'", ' ')}'"
    end

    private

    def log(message)
      Rails.logger.info message
    end
  end
end
