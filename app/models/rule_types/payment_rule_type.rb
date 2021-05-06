module RuleTypes
  class PaymentRuleType < BaseRuleType
    def initialize(rule)
      @rule = rule
    end

    def project
      rule.payment_rule.project
    end

    def available_variables
      var_names = []

      rules = payment_rule.packages.flat_map(&:rules).select(&:package_kind?).select{|r| r.package.kind != "zone"}
      var_names << rules.flat_map(&:formulas).map(&:code)
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }

      var_names << decision_tables.map(&:out_headers) if decision_tables.any?
      var_names.flatten.uniq.reject(&:nil?).sort
    end

    def available_variables_for_values
      var_names = []

      if payment_rule.monthly?
        var_names << payment_rule.packages
                                 .flat_map(&:package_rule)
                                 .map(&:formulas)
                                 .flatten
                                 .map(&:code)
                                 .map { |code| "#{code}_values" }
        var_names << payment_rule.rule.formulas.map(&:code).map { |code| "#{code}_previous_values" }
      end

      var_names.flatten
    end

    def fake_facts
      facts = {}
      packages = payment_rule.packages
      # in case we are in a clone packages a not there so go through long road
      packages = payment_rule.package_payment_rules.flat_map(&:package) if packages.empty?
      rules = packages.flat_map(&:rules).select(&:package_kind?)
      rules.flat_map(&:formulas).each do |formula|
        facts[formula.code] = "1040.1"
      end
      facts
    end
  end
end
