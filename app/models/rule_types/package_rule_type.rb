module RuleTypes
  class PackageRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def used_formulas(formula)
      used = super

      if package.activity_rule
        dependencies = formula.dependencies
        package.activity_rule.formulas.each do |f|
          if dependencies.include?("#{f.code}_values")
            used.push(f) 
          end
        end
      end

     
      used
    end

    def used_by_formulas(formula)
      used_by = super
      if rule.package.zone_rule
        rule.package.zone_rule.formulas.each do |f|
          if f.dependencies.include?("#{formula.code}_values")
            used_by.push(f) 
          end
        end
      end 

      rule.package.payment_rules.each do |payment_rule|
        payment_rule.rule.formulas.each do |f|
          if f.dependencies.include?("#{formula.code}_values")
            used_by.push(f) 
          end
          if f.dependencies.include?(formula.code)
            used_by.push(f) 
          end
        end
      end

      used_by
    end

    def package_formula_uniqness
      formula_by_codes = formulas.group_by(&:code)
      if package.project
        all_package_formulas = package.project.packages.flat_map(&:rules).select(&:package_kind?).flat_map(&:formulas)
        all_formulas_by_codes = all_package_formulas.group_by(&:code)
        all_formulas_by_codes.each do |code, non_uniq_formulas|
          next unless formula_by_codes[code]

          if non_uniq_formulas.size > 1
            rule.errors.add(:formulas, "Formula's code must be unique accross packages, you have #{non_uniq_formulas.size} formulas with '#{code}' in #{non_uniq_formulas.map(&:rule).map(&:package).map(&:name).join(' and ')}")
          end
        end
      end

      formula_by_codes.each do |code, formulas|
        if formulas.size > 1
          rule.errors.add(:formulas, "Formula's code must be unique, you have #{formulas.size} formulas with '#{code}'")
        end
      end
    end

    def available_variables
      var_names = []

      var_names << available_variables_for_values.map { |code| "%{#{code}}" }

      var_names << package.zone_rule.formulas.map(&:code) if package.zone_rule

      var_names << decision_tables.map(&:out_headers) if decision_tables.any?
      var_names.flatten.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      var_names = []
      if package.activity_rule
        var_names << package.activity_rule.formulas.map(&:code).map { |code| "#{code}_values" }
      end

      var_names.flatten
    end

    def fake_facts
      # in case we are in a clone packages a not there so go through long road package_states instead of package.states
      to_fake_facts([])
        .merge(zone_rule_fake_facts)
    end

    def zone_rule_fake_facts
      return {} unless package.zone_rule

      zone_formula_codes = rule
                           .formulas
                           .each_with_object({}) do |formula, hash|
        hash["#{formula.code}_values".to_sym] = formula.code
      end

      package.zone_rule.formulas.each_with_object({}) do |formula, facts|
        facts[formula.code] = format(formula.expression, zone_formula_codes)
      end
    end
  end
end
