# frozen_string_literal: true

module Descriptor
  class RuleDescription
    def initialize(rule)
      @rule = rule
    end

    def activity_formulas_descriptors
      return {} unless rule

      rule.formulas.each_with_object({}) do |formula, hash|
        hash[formula.code] = formula_descriptor(formula)
      end
    end

    def formulas_descriptors
      formulas = {}
      return formulas unless rule

      rule.formulas.each do |formula|
        #next unless formula.formula_mapping
        formulas[formula.code] = formula_descriptor_with_de(formula)
      end
      formulas
    end

    private

    attr_reader :rule

    def formula_descriptor_with_de(formula)
      formula_descriptor(formula).tap do |descriptor|
        descriptor[:de_id] = formula&.formula_mapping&.external_reference
      end
    end

    def formula_descriptor(formula)
      {
        short_name:              formula.short_name || formula.description,
        description:             formula.description,
        expression:              formula.expression,
        frequency:               formula.frequency ||
          rule.package&.frequency ||
          rule.payment_rule&.frequency,
        exportable_formula_code: formula.exportable_formula_code
      }
    end
  end
end
