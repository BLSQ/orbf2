module RuleTypes
  class BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    attr_reader :rule
    delegate :package, to: :rule
    delegate :formulas, to: :rule
    delegate :activity_kind?, to: :rule
    delegate :package_kind?, to: :rule
    delegate :multi_entities_kind?, to: :rule
    delegate :payment_kind?, to: :rule
    delegate :decision_tables, to: :rule
    delegate :payment_rule, to: :rule

    def used_formulas(formula)
      dependencies = formula.dependencies
      used = formulas.select { |f| dependencies.include?(f.code) }
      if formula.exportable_formula_code.presence
        used += formulas.select { |f| f.code == formula.exportable_formula_code }
      end
      used
    end

    def used_by_formulas(formula)
      used_by = formulas.select { |f| f.dependencies.include?(formula.code) }

      used_by += formulas.select { |f| f.exportable_formula_code == formula.code }

      used_by
    end

    # returns an array of modified formula expression or exportable_formula_code
    def refactor(formula, new_code)
      used_by = used_by_formulas(formula)

      used_by.each do |used_by_formula|
        tokens = Orbf::RulesEngine::Tokenizer.tokenize(used_by_formula.expression)
        new_expression = tokens.map { |token| token == formula.code ? new_code : token }.join
        if used_by_formula.expression != new_expression
          puts "refactoring formula #{used_by_formula.id} : #{used_by_formula.code} := #{used_by_formula.expression} to #{new_expression}"
          used_by_formula.expression = new_expression
        end

        if used_by_formula.exportable_formula_code.presence && used_by_formula.exportable_formula_code == formula.code
          puts "updating exportable_formula_code #{used_by_formula.id} : #{used_by_formula.exportable_formula_code} to #{new_code}"
          used_formula.exportable_formula_code = new_code
        end
      end

      used_by
    end

    def package_states
      package.package_states.map(&:state)
    end

    def to_fake_facts(states)
      facts = states.map { |state| [state.code.to_sym, "10"] }.to_h

      facts[:year] = 2016
      facts[:month_of_year] = 6
      facts[:quarter_of_year] = 2
      facts[:month_of_quarter] = 3
      org_unit_facts = decision_tables.flat_map(&:out_headers)
                                      .map { |header| [header.to_sym, "10"] }
                                      .to_h
      facts.merge org_unit_facts
    end

    def package_formula_uniqness
      formula_by_codes = formulas.group_by(&:code)

      formula_by_codes.each do |code, formulas|
        next unless formulas.size > 1

        rule.errors[:formulas] << "Formula's code must be unique,"\
          " you have #{formulas.size} formulas with '#{code}'"
      end
    end
  end
end
