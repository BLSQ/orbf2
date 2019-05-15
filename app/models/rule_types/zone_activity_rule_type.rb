# frozen_string_literal: true

module RuleTypes
  class ZoneActivityRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def available_variables
      variables = []
      variables += rule.formulas.map(&:code)
      variables += available_variables_for_values.map { |code| "%{#{code}}" }
      variables << "org_units_count"
      variables
    end

    def available_variables_for_values
      rule.package.activity_rule.formulas.collect do |f|
        [f.code, "values"].join("_")
      end
    end

    def fake_facts
      to_fake_facts(package_states).merge(org_units_count: 1)
    end
  end
end
