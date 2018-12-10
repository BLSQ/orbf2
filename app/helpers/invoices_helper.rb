# frozen_string_literal: true

module InvoicesHelper
  def invoice_output_input_class(total_item)
    total_item.formula.dhis2_mapping ? "formula-output" : nil
  end

  def invoice_output_input_act_class(activity_item, code)
    begin
      activity_item.input?(code)
    rescue StandardError
      return ""
    end
    if activity_item.input?(code)
      "formula-input"
    elsif activity_item.output?(code)
      "formula-output"
    end
  end

  def project_descriptor(project)
    {
      payment_rules: project.payment_rules.each_with_object({}) do |payment_rule, hash|
        hash[codify(payment_rule.rule.name)] = payment_descriptor(payment_rule)
      end
    }
  end

  def codify(code)
    Orbf::RulesEngine::Codifier.codify(code)
  end

  def package_descriptor(package)
    package_descriptor = {
      name:                      package.name,
      code:                      package.code,
      frequency:                 package.frequency,
      kind:                      package.kind,
      activities:                activity_descriptors(package),
      data_set_ids:              package.package_states.map(&:ds_external_reference).compact,
      data_element_group_ids:    package.package_states.map(&:deg_external_reference).compact,
      main_org_unit_group_ids:   package.main_entity_groups
                                        .map(&:organisation_unit_group_ext_ref).compact,
      target_org_unit_group_ids: package.target_entity_groups
                                        .map(&:organisation_unit_group_ext_ref).compact,
      groupset_ext_id:           package.ogs_reference,
      matching_groupset_ids:     package.groupsets_ext_refs
    }

    package_descriptor[:activity_formulas] = activity_rule_descriptors(package)
    package_descriptor[:formulas] = formulas_descriptors(package.package_rule)
    package_descriptor[:zone_formulas] = formulas_descriptors(package.zone_rule)

    package_descriptor
  end

  def activity_rule_descriptors(package)
    return {} unless package.activity_rule

    package.activity_rule.formulas.each_with_object({}) do |formula, hash|
      hash[formula.code] = {
        short_name:              formula.short_name || formula.description,
        description:             formula.description,
        expression:              formula.expression,
        frequency:               formula.frequency || package.frequency,
        exportable_formula_code: formula.exportable_formula_code
      }
    end
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
      name:             payment_rule.rule.name,
      frequency:        payment_rule.frequency,
      formulas:         formulas_descriptors(payment_rule.rule),
      packages:         payment_rule.packages.each_with_object({}) do |package, hash|
        hash[package.code] = package_descriptor(package)
      end,
      output_data_sets: payment_rule.datasets.map do |ds|
        {
          frequency: ds.frequency,
          id:        ds.external_reference
        }
      end
    }
  end

  def formulas_descriptors(rule)
    formulas = {}
    return formulas unless rule

    rule.formulas.each do |formula|
      next unless formula.formula_mapping

      formulas[formula.code] = {
        de_id:                   formula.formula_mapping&.external_reference,
        short_name:              formula.short_name || formula.description,
        description:             formula.description,
        expression:              formula.expression,
        frequency:               formula.frequency || rule.package&.frequency || rule.payment_rule&.frequency,
        exportable_formula_code: formula.exportable_formula_code
      }
    end
    formulas
  end

  def as_pretty_json_string(object)
    JSON.pretty_generate(JSON.parse(object.to_json))
  end
end
