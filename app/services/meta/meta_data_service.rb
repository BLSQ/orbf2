

class Meta::MetaDataService
  def initialize(project)
    @project = project
    @data_compound ||= DataCompound.from(project)
  end

  def metadatas
    build_package_formula_mappings_meta_datas +
      build_activity_states_meta_datas
  end

  private

  attr_reader :data_compound, :project

  def build_package_formula_mappings_meta_datas
    project.packages.each_with_object([]) do |package, metadatas|
      package.rules.each do |rule|
        rule.formulas.each do |formula|
          formula.formula_mappings.each do |formula_mapping|
            data_element = data_compound.data_element(formula_mapping.external_reference)
            metadatas.push(
              Meta::Metadata.new(
                dhis2_id:         formula_mapping.external_reference,
                formula_mapping:  formula_mapping,
                package:          package,
                orbf_type:        "Formula mapping",
                dhis2_code:       data_element.code,
                dhis2_name:       data_element.name,
                dhis2_short_name: data_element.short_name,
                orbf_code:        [formula_mapping.activity&.code, formula_mapping.formula&.code].join(" - "),
                orbf_name:        [formula_mapping.activity&.name, formula_mapping.formula&.code.humanize].join(" - "),
                orbf_short_name:  [formula_mapping.activity&.short_name, formula_mapping.formula&.code.humanize].join(" - ")
              )
            )
          end
        end
      end
    end
  end

  def build_activity_states_meta_datas
    project.activities.each_with_object([]) do |activity, metadatas|
      activity.activity_states.each do |activity_state|
        next unless activity_state.external_reference
        activity_state.activity.activity_packages.each do |activity_package|
          data_element = data_compound.data_element(activity_state.external_reference)
          metadatas.push(
            Meta::Metadata.new(
              dhis2_id:         activity_state.external_reference,
              activity_state:   activity_state,
              package:          activity_package.package,
              orbf_type:        "Activity state",
              dhis2_code:       data_element.code,
              dhis2_name:       data_element.name,
              dhis2_short_name: data_element.short_name,
              orbf_code:        activity_state.activity.code + "-" + activity_state.state.code,
              orbf_name:        activity_state.activity.name + " - " + activity_state.state.name,
              orbf_short_name:  activity_state.activity.short_name
            )
          )
        end
      end
    end
  end
end
