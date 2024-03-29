# frozen_string_literal: true

module RuleTypes
  class ActivityRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def used_formulas(formula)
      used = super

      formulas.each do |f| 
        if formula.dependencies.include?("#{f.code}_current_quarter_values")
          used.push(f)
        end
      end

      used
    end

    def used_by_formulas(formula)
      used = super

      formulas.each do |f| 
        if f.dependencies.include?("#{formula.code}_current_quarter_values")
          used.push(f)
        end
      end
      if package.package_rule
        package.package_rule.formulas.each do |f|
          if f.dependencies.include?("#{formula.code}_values")
            used.push(f) 
          end
        end
      end
      used
    end

    def refactor(formula, new_code)
      used_by = super 

      substitions = {
        formula.code+"_current_quarter_values" => new_code+"_current_quarter_values",
        formula.code+"_values" => new_code+"_values"
      }
      
      used_by.each do |used_by_formula|
        tokens = Orbf::RulesEngine::Tokenizer.tokenize(used_by_formula.expression)
        new_expression = tokens.map { |token| substitions[token] || token }.join
        if new_expression != used_by_formula.expression
          puts "refactoring formula #{used_by_formula.id} : #{used_by_formula.code} := #{used_by_formula.expression} to #{new_expression}"
          used_by_formula.expression = new_expression
        end
      end

      used_by 
    end

    def available_variables
      var_names = []

      if package
        var_names.push(*package_states.map(&:code))
        var_names.push(*null_states)
      end
      if package.monthly?
        var_names.push(*package_states.map { |s| s.code + "_quarterly" })
      end
      var_names.push(*formulas.map(&:code))
      var_names.push(*Analytics::Locations::LevelScope.new.facts(package))
      var_names.push(*available_variables_for_values.map { |code| "%{#{code}}" })
      var_names.push("year")
      var_names.push("quarter_of_year")
      var_names.push("month_of_year")
      var_names.push("month_of_quarter")
      if project.new_engine? && package.package_rule
        var_names.push(*package.package_rule.formulas.map(&:code))
      end

      if package.multi_entities?
        var_names.push("org_units_sum_if_count") if package.multi_entities_rule
        var_names.push("org_units_count")
      end

      var_names.push(*main_orgunit_states) if package&.zone_kind?

      var_names.push(*decision_tables.flat_map(&:out_headers)) if decision_tables.any?
      var_names.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      var_names = []

      activity_level_states = package_states
      Analytics::Timeframe.all_variables_builders.each do |timeframe|
        var_names.push(*activity_level_states.map { |state| "#{state.code}#{timeframe.suffix}" })
      end

      if project&.new_engine?
        var_names.push(*rule.formulas.map { |formula| "#{formula.code}_current_quarter_values" })
        var_names.push(*activity_level_states.map { |formula| "#{formula.code}_current_quarter_quarterly_values" })

        if package.monthly?
          (1..12).each do |i|
            monthly_vars = activity_level_states.each_with_object([]) do |formula, result|
              push_window_values(result, formula, "months", i)
            end
            var_names.push(*monthly_vars)
          end
        end

        if access_to_quarterly_values?
          (1..4).each do |i|
            quarterly_vars = activity_level_states.each_with_object([]) do |formula, result|
              push_window_values(result, formula, "quarters", i)
            end
            var_names.push(*quarterly_vars)
          end
        end
      end

      if package.multi_entities_rule
        var_names.push(*package.multi_entities_rule.formulas.map { |f| f.code + "_values" })
      end

      var_names
    end

    def push_window_values(result, formula, time_unit, i)
      result << "#{formula.code}_last_#{i}_#{time_unit}_window_values"
      result << "#{formula.code}_is_null_last_#{i}_#{time_unit}_window_values"
      result << "#{formula.code}_last_#{i}_#{time_unit}_exclusive_window_values"
      result << "#{formula.code}_is_null_last_#{i}_#{time_unit}_exclusive_window_values"
    end

    def fake_facts
      # in case we are in a clone packages a not there so go through long road package_states instead of states

      quarterly_facts = package.monthly? ? package_states.map { |state| ["#{state.code}_quarterly".to_sym, "10"] }.to_h : {}

      to_fake_facts(package_states)
        .merge(quarterly_facts)
        .merge(
          Analytics::Locations::LevelScope.new.to_fake_facts(package)
        )
        .merge("org_units_count" => "1", "org_units_sum_if_count" => "1")
        .merge(package_rules_facts)
        .merge(null_facts)
        .merge(main_orgunit_facts)
        .merge(package_decision_table_facts)
    end

    private

    def access_to_quarterly_values?
      package.monthly? || package.quarterly?
    end

    def main_orgunit_states
      package_states.map { |state| "#{state.code}_zone_main_orgunit" }
    end

    def main_orgunit_facts
      main_orgunit_states.each_with_object({}) do |main_orgunit_state, hash|
        hash[main_orgunit_state] = 0
      end
    end

    def null_states
      package_states.map { |state| "#{state.code}_is_null" }
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

    def package_decision_table_facts
      return {} unless project.new_engine? && package.package_rule

      package.package_rule
             .decision_tables
             .each_with_object({})
             .each do |decision_table, facts|
        decision_table.out_headers.each do |header|
          facts[header] = "1"
        end
      end
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
