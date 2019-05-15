module RuleTypes
  class MultiEntityRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def available_variables
      var_names = []
      var_names << package_states.map(&:code)
      var_names << decision_tables.map(&:out_headers) if decision_tables.any?
      var_names.flatten.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      []
    end

    def fake_facts
      to_fake_facts(package_states)
    end
  end
end
