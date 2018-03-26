module RuleTypes
  class ActivityRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def available_variables
      var_names = []
      if package
        var_names.push(*package.states.select(&:activity_level?).map(&:code))
        var_names.push(*null_states)
      end
      var_names.push(*formulas.map(&:code))
      var_names.push(*Analytics::Locations::LevelScope.new.facts(package))
      var_names.push(*available_variables_for_values.map { |code| "%{#{code}}" })
      var_names.push("quarter_of_year")
      var_names.push("month_of_year")

      if project.new_engine? && package.package_rule
        var_names.push(*package.package_rule.formulas.map(&:code))
      end

      if package.multi_entities?
        var_names.push("org_units_sum_if_count") if package.multi_entities_rule
        var_names.push("org_units_count")
      end

      var_names.push(*decision_tables.flat_map(&:out_headers)) if decision_tables.any?
      var_names.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      var_names = []

      activity_level_states = package.package_states.map(&:state).select(&:activity_level?)
      Analytics::Timeframe.all_variables_builders.each do |timeframe|
        var_names << activity_level_states.map { |state| "#{state.code}#{timeframe.suffix}" }
      end
      if package.multi_entities_rule
        var_names << package.multi_entities_rule.formulas.map { |f| f.code + "_values" }
      end

      var_names.flatten
    end

    def fake_facts
      # in case we are in a clone packages a not there so go through long road package_states instead of states
      to_fake_facts(package.package_states.map(&:state).select(&:activity_level?))
        .merge(
          Analytics::Locations::LevelScope.new.to_fake_facts(package)
        )
        .merge("org_units_count" => "1", "org_units_sum_if_count" => "1")
        .merge(package_rules_facts)
        .merge(null_facts)
    end

    private

    def null_states
      package.states.select(&:activity_level?).map { |state| "#{state.code}_is_null" }
    end

    def null_facts
      null_states.each_with_object({}) do |null_state, hash|
        hash[null_state] = 0
      end
    end

    def package_rules_facts
      return {} unless project.new_engine? && package.package_rule
      activity_formula_codes = activity_formula_as_values

      package_facts = package.package_rule
                             .formulas
                             .each_with_object({})
                             .each do |formula, facts|
        facts[formula.code] = format(formula.expression, activity_formula_codes)
      end

      zone_facts.merge(package_facts)
    end

    def activity_formula_as_values
      rule.formulas.each_with_object({}) do |formula, hash|
        hash["#{formula.code}_values".to_sym] = formula.code
      end
    end

    def zone_facts
      return {} unless package.zone_rule
      package.zone_rule
             .formulas
             .each_with_object({}) do |zone_formula, hash|
        hash[zone_formula.code] = "1"
      end
    end
  end
end
