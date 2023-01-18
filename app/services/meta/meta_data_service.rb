module Meta
  class MetaDataService
    def initialize(project)
      @project = project
      @data_compound ||= DataCompound.from(project)
    end

    def metadatas
      build_package_formula_mappings_meta_datas +
        build_activity_states_meta_datas +
        build_payment_formula_mappings_meta_datas
    end

    private

    attr_reader :data_compound, :project

    def dhis2_props(data_element_id)
      data_element = data_compound.data_element(data_element_id)
      {
        dhis2_id:         data_element_id,
        dhis2_code:       data_element&.code,
        dhis2_name:       data_element&.name,
        dhis2_short_name: data_element&.short_name
      }
    end

    def build_package_formula_mappings_meta_datas
      project.packages.each_with_object([]) do |package, metadatas|
        package.rules.each do |rule|
          rule.formulas.each do |formula|
            formula.formula_mappings.each do |formula_mapping|
              metadatas.push(new_meta_formula_mapping(formula_mapping, package))
            end
          end
        end
      end
    end

    def new_meta_formula_mapping(formula_mapping, package)
      name = formula_mapping.names
      Meta::Metadata.new(
        **dhis2_props(formula_mapping.external_reference).merge(
          formula_mapping: formula_mapping,
          package:         package,
          orbf_type:       "Formula mapping",
          orbf_name:       name.long,
          orbf_short_name: name.short,
          orbf_code:       name.code
        )
      )
    end

    def build_activity_states_meta_datas
      project.activities.each_with_object([]) do |activity, metadatas|
        activity.activity_states.each do |activity_state|
          next unless activity_state.external_reference

          activity_state.activity.activity_packages.each do |activity_package|
            metadatas.push(new_meta_activity_state(activity_state, activity_package))
          end
        end
      end
    end

    def new_meta_activity_state(activity_state, activity_package)
      name = activity_state.state.names(
        project.naming_patterns, activity_state.activity
      )
      Meta::Metadata.new(
        **dhis2_props(activity_state.external_reference).merge(
          activity_state:  activity_state,
          package:         activity_package.package,
          orbf_type:       "Activity state",
          orbf_code:       name.code,
          orbf_name:       name.long,
          orbf_short_name: name.short
        )
      )
    end

    def build_payment_formula_mappings_meta_datas
      project.payment_rules.each_with_object([]) do |payment_rule, metadatas|
        payment_rule.rule.formulas.each do |formula|
          formula.formula_mappings.each do |formula_mapping|
            metadatas.push(new_meta_payment_mapping(formula_mapping, payment_rule))
          end
        end
      end
    end

    def new_meta_payment_mapping(formula_mapping, payment_rule)
      name = formula_mapping.names

      Meta::Metadata.new(
        dhis2_props(formula_mapping.external_reference).merge(
          formula_mapping: formula_mapping,
          payment_rule:    payment_rule,
          orbf_type:       "Payment mapping",
          orbf_code:       name.code,
          orbf_name:       name.long,
          orbf_short_name: name.short
        )
      )
    end
  end
end
