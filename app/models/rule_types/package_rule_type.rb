module RuleTypes
class PackageRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.package.project
    end

    def package_formula_uniqness
      formula_by_codes = formulas.group_by(&:code)
      if package.project
        all_package_formulas = package.project.packages.flat_map(&:rules).select(&:package_kind?).flat_map(&:formulas)
        all_formulas_by_codes = all_package_formulas.group_by(&:code)
        all_formulas_by_codes.each do |code, non_uniq_formulas|
          next unless formula_by_codes[code]
          if non_uniq_formulas.size > 1
            rule.errors[:formulas] << "Formula's code must be unique accross packages, you have #{non_uniq_formulas.size} formulas with '#{code}' in #{non_uniq_formulas.map(&:rule).map(&:package).map(&:name).join(' and ')}"
          end
        end
      end

      formula_by_codes.each do |code, formulas|
        rule.errors[:formulas] << "Formula's code must be unique, you have #{formulas.size} formulas with '#{code}'" if formulas.size > 1
      end
    end

    def available_variables
      var_names = []

      var_names << package.states.select(&:package_level?).map(&:code) if package
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }

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
      to_fake_facts(package.package_states.map(&:state).select(&:package_level?))
    end
  end
end