module Invoicing
  class IndexedProject
    attr_reader :project, :orbf_project
    LookupRules = Struct.new(:project, :package, :rule, :payment_rule)
    def initialize(project, orbf_project)
      @project = project
      @orbf_project = orbf_project
      @activity_items_lookup = activity_item_lookup
      @total_items_lookup = total_item_lookup
      @activity_states_lookup = activity_mappings
    end

    def lookup_package_rule(activity_item, header)
      variable = activity_item.variable(header)
      @activity_items_lookup[[variable.formula.rule.kind, variable.formula.code]]
    end

    def lookup_rule(total_item)
      if total_item.formula.rule.kind != "payment"
        @activity_items_lookup[[total_item.formula.rule.kind, total_item.formula.code]]
      else
        @total_items_lookup[[total_item.formula.rule.kind, total_item.formula.code]]
      end
    end

    def lookup_activity_state(variable)
      @activity_states_lookup[[variable.activity_code, variable.state]]
    end

    private

    def activity_mappings
      orbf_project.packages.each_with_object({}) do |package, act_maps|
        package.activities.each do |activity|
          activity.activity_states.each do |activity_state|
            act_maps[[activity.activity_code, activity_state.state]] = activity_state
          end
        end
      end
    end

    def activity_item_lookup
      project.packages.each_with_object({}) do |package, invoice_activities|
        package.rules.each do |rule|
          rule.formulas.each do |formula|
            invoice_activities[[rule.kind, formula.code]] = LookupRules.new(
              project,
              package,
              rule,
              nil
            )
          end
        end
      end
    end

    def total_item_lookup
      project.payment_rules.each_with_object({}) do |payment_rule, invoice_payment_formula|
        payment_rule.rule.formulas.each do |formula|
          invoice_payment_formula[[payment_rule.rule.kind, formula.code]] = LookupRules.new(
            project,
            nil,
            nil,
            payment_rule
          )
        end
      end
    end
  end
end
