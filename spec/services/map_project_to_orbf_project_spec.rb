# frozen_string_literal: true

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

    orbf_project = MapProjectToOrbfProject.new(project, [], [], []).map
    expect(orbf_project).to be_a(Orbf::RulesEngine::Project)
    expect(orbf_project.default_combos_ext_ids).to eq(
      default_attribute_option_combo_ext_id: "aoc_reference",
      default_category_option_combo_ext_id:  "coc_reference"
    )
    expect(orbf_project.packages.first).to be_a(Orbf::RulesEngine::Package)
    expect(orbf_project.packages.size).to eq project.packages.size

    orbf_formula_with_frequency = orbf_project.packages.last.activity_rules.first.formulas.last

    expect(orbf_formula_with_frequency.frequency).to eq("yearly")
    expect(orbf_formula_with_frequency.code).to eq(formula_with_frequency.code)
    expect(orbf_formula_with_frequency.expression).to eq(formula_with_frequency.expression)
    expect(orbf_formula_with_frequency.dhis2_mapping_de(activity.code)).to eq("dhis2_out")
    expect(orbf_formula_with_frequency.dhis2_mapping_coc(activity.code)).to eq(nil)

    orbf_package_formula = orbf_project.packages.last.package_rules.first.formulas.last
    expect(orbf_package_formula.dhis2_mapping_de).to eq("package_dhis2_out")
    expect(orbf_package_formula.dhis2_mapping_coc).to eq(nil)

    expect(orbf_project.packages.last.include_main_orgunit?).to eq(false)
    # dump with yaml to support circular references
    puts YAML.dump(orbf_project)
  end

  it "should map zone activity rule mappings" do
    project = full_project

    package = project.packages.build(name: "zone_test", kind: "zone", frequency: "monthly")
    package.package_entity_groups.build(kind: "main", organisation_unit_group_ext_ref: "mainextid")
    package.package_entity_groups.build(kind: "target", organisation_unit_group_ext_ref: "targetextid")
    package.include_main_orgunit = true

    activity1 = project.activities[0]
    activity2 = project.activities[1]
    package.activities << activity1
    package.activities << activity2

    rule = package.rules.build(kind: "zone_activity")
    formula = rule.formulas.build(expression: "1", code: "z_act")
    formula.formula_mappings.build(
      external_reference: "act1",
      activity:           package.activities[0]
    )
    formula.formula_mappings.build(
      external_reference: "act2",
      activity:           package.activities[1]
    )

    orbf_project = MapProjectToOrbfProject.new(project, [], [], []).map
    orbf_formula = orbf_project.packages.last.zone_activity_rules.first.formulas.first
    expect(orbf_formula.send(:activity_mappings)).to eq(
      activity1.code => "act1",
      activity2.code => "act2"
    )
    expect(orbf_project.packages.last.include_main_orgunit?).to eq(true)
  end
end
