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
      var_names << package.states.select(&:activity_level?).map(&:code)
      var_names << decision_tables.map(&:out_headers) if decision_tables.any?
      var_names.flatten.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      []
    end

    def fake_facts
      to_fake_facts(package.package_states.map(&:state).select(&:activity_level?))
    end
  end
end
