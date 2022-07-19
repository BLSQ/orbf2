module RuleTypes
  class ZoneRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def used_formulas(formula)
      used = super

      if rule.package.package_rule
        dependencies = formula.dependencies
        rule.package.package_rule.formulas.each do |f|
          if dependencies.include?("#{f.code}_values")
            used.push(f) 
          end
        end
      end
      used
    end

    def used_by_formulas(formula)
      used_by = super
      if rule.package.package_rule
        rule.package.package_rule.formulas.each do |f|
          if f.dependencies.include?(f.code)
            used.push(f) 
          end
        end
      end
      used_by
    end

    def available_variables
      return [] unless rule.package.package_rule

      var_names = []

      var_names << available_variables_for_values.map { |code| "%{#{code}}" }
      var_names << package.zone_rule.formulas.map(&:code) if package.zone_rule

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
