module RuleTypes
  class ZoneRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def available_variables
      return [] unless rule.package.package_rule
      var_names = []

      var_names << available_variables_for_values.map { |code| "%{#{code}}" }

      var_names.flatten.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      rule.package.package_rule.formulas.map do |formula|
        formula.code + "_values"
      end
    end

    def fake_facts
      rule.package.package_rule.formulas.each_with_object({}) do |formula, facts|
        facts[formula.code + "_values"] = 1
      end
    end
  end
end
