
module InvoicesHelper
  def invoice_output_input_class(total_item)
    total_item.formula.dhis2_mapping ? "formula-output" : nil
  end

  def invoice_output_input_act_class(activity_item, code)
    if activity_item.input?(code)
     "formula-input"
    elsif activity_item.output?(code)
     "formula-output"
    end
  end

  def project_descriptor(project)
    {
      payment_rules: project.payment_rules.map { |payment_rule| payment_descriptor(payment_rule) }
    }
  end

  def package_descriptor(package)
    {
      name:       package.name,
      frequency:  package.frequency,
      formulas:   formulas_descriptors(package.package_rule),
      activities: activity_descriptors(package)
    }
  end

  def activity_descriptors(package)
    activity_descriptors = []
    package.activities.each do |activity|
      activity_descriptor = { "name" => activity.name }
      activity_descriptor["code"] = activity.code if activity.code.present?
      activity_descriptors.push(activity_descriptor)

      package.states.each do |state|
        if activity.activity_state(state)&.external_reference.present?
          activity_descriptor[state.code] = activity.activity_state(state)&.external_reference
        end
      end
      package.activity_rule.formulas.each do |formula|
        if formula.formula_mapping(activity)
          activity_descriptor[formula.code] = formula.formula_mapping(activity)&.external_reference
        end
      end
    end
    activity_descriptors
  end

  def payment_descriptor(payment_rule)
    {
      name:     payment_rule.rule.name,
      formulas: formulas_descriptors(payment_rule.rule),
      packages: payment_rule.packages.map { |package| package_descriptor(package) }
    }
  end

  def formulas_descriptors(rule)
    formulas = {}
    rule.formulas.each do |formula|
      next unless formula.formula_mapping
      formulas[formula.code] = {
        de_id:      formula.formula_mapping&.external_reference,
        expression: formula.expression,
        frequency:  formula.frequency || rule.package&.frequency || rule.payment_rule&.frequency
      }
    end
    formulas
  end

  def as_pretty_json_string(object)
    JSON.pretty_generate(JSON.parse(object.to_json))
  end
end