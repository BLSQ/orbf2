require "rails_helper"
RSpec.describe MapProjectToOrbfProject do
  include_context "basic_context"

  it "should instantiate a valid project" do
    project = full_project
    project.default_coc_reference = "coc_reference"
    project.default_aoc_reference = "aoc_reference"

    package = project.packages.last
    activity = package.activities.first
    formula_with_frequency = package.activity_rule.formulas.last
    formula_with_frequency.frequency = "yearly"
    formula_with_frequency.formula_mappings.create!(
      kind:               "activity",
      activity:           activity,
      external_reference: "dhis2_out"
    )

    package_formula = package.package_rule.formulas.last
    package_formula.formula_mappings.create!(
      kind:               "package",
      external_reference: "package_dhis2_out"
    )

    orbf_project = MapProjectToOrbfProject.new(project, []).map
    expect(orbf_project).to be_a(Orbf::RulesEngine::Project)
    expect(orbf_project.default_combos_ext_ids).to eq(
      default_attribute_option_combo_ext_id: "aoc_reference",
      default_category_option_combo_ext_id: "coc_reference",
    )
    expect(orbf_project.packages.first).to be_a(Orbf::RulesEngine::Package)
    expect(orbf_project.packages.size).to eq project.packages.size

    orbf_formula_with_frequency = orbf_project.packages.last.activity_rules.first.formulas.last

    expect(orbf_formula_with_frequency.frequency).to eq("yearly")
    expect(orbf_formula_with_frequency.code).to eq(formula_with_frequency.code)
    expect(orbf_formula_with_frequency.expression).to eq(formula_with_frequency.expression)
    expect(orbf_formula_with_frequency.dhis2_mapping(activity.code)).to eq("dhis2_out")

    orbf_package_formula = orbf_project.packages.last.package_rules.first.formulas.last
    expect(orbf_package_formula.dhis2_mapping).to eq("package_dhis2_out")
    # dump with yaml to support circular references
    puts YAML.dump(orbf_project)
  end
end
