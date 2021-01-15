# frozen_string_literal: true

module Descriptor
  class ProjectDescriptorFactory
    def project_descriptor(project)
      {
        status:        project.status,
        start_date:    project.publish_date,
        end_date:      project.publish_end_date,
        payment_rules: payment_rule_descriptors(project),
        entity_group:  {
          id:   project.entity_group.external_reference,
          name: project.entity_group.name
        }
      }
    end

    def package_descriptor(package)
      package_description = PackageDescription.new(package)
      descr = {
        name:                      package.name,
        description:               package.description,
        code:                      package.code,
        frequency:                 package.frequency,
        kind:                      package.kind,
        activities:                package_description.activity_descriptors(:activity_rule),
        data_set_ids:              package_description.data_set_ids,
        data_element_group_ids:    package_description.data_element_group_ids,
        main_org_unit_group_ids:   package_description.main_org_unit_group_ids,
        target_org_unit_group_ids: package_description.target_org_unit_group_ids,
        groupset_ext_id:           package.ogs_reference,
        matching_groupset_ids:     package.groupsets_ext_refs,
        deg_ext_id:                package.deg_external_reference,
        activity_formulas:         activity_formulas_descriptors(package),
        formulas:                  formulas_descriptors(package.package_rule)
      }
      if package.zone_kind?
        descr[:zone_activities] = package_description.activity_descriptors(:zone_activity_rule)
        descr[:zone_formulas] = formulas_descriptors(package.zone_rule)
        descr[:zone_activity_formulas] = zone_activity_formulas_descriptors(package)
      end
      descr
    end

    def payment_rule_descriptors(project)
      project.payment_rules.each_with_object({}) do |payment_rule, hash|
        hash[payment_rule.code] = payment_descriptor(payment_rule)
      end
    end

    def payment_descriptor(payment_rule)
      {
        name:             payment_rule.rule.name,
        frequency:        payment_rule.frequency,
        formulas:         formulas_descriptors(payment_rule.rule),
        packages:         package_descriptors(payment_rule),
        output_data_sets: payment_rule.datasets.map do |ds|
          {
            frequency: ds.frequency,
            id:        ds.external_reference
          }
        end
      }
    end

    def package_descriptors(payment_rule)
      payment_rule.packages.each_with_object({}) do |package, hash|
        hash[package.code] = package_descriptor(package)
      end
    end

    def formulas_descriptors(rule)
      RuleDescription.new(rule).formulas_descriptors
    end

    def activity_formulas_descriptors(package)
      RuleDescription.new(package.activity_rule).activity_formulas_descriptors
    end

    def zone_activity_formulas_descriptors(package)
      RuleDescription.new(package.zone_activity_rule).activity_formulas_descriptors
    end
  end
end
