# frozen_string_literal: true

require "rails_helper"
describe Descriptor::ProjectDescriptorFactory do
  include_context "basic_context"
  describe "With basic project" do
    let(:expected_descriptor) { JSON.parse(fixture_content(:scorpio, "project_descriptor.json")) }

    it "should serialize to hash usage for invoice coding" do
      project = full_project

      project.payment_rules.first.datasets.create!(frequency: "quarterly", external_reference: "aze123")

      expect_descriptor(project, expected_descriptor)
    end
  end
  describe "With Zone package" do
    let(:expected_descriptor) { JSON.parse(fixture_content(:scorpio, "project_descriptor_for_zone.json")) }

    it "handles zone activity rules formulas and mappings" do
      project = full_project
      quantity_package = project.packages.first
      rule = quantity_package.rules.build(
        name: "Zone points",
        kind: "zone_activity"
      )

      formulas = rule.formulas.build(
        rule:        rule,
        code:        :zone_points_per_org,
        expression:  "SUM(%{amount_values})/org_units_count ",
        description: "Zone points per org"
      )
      formulas.formula_mappings.build(
        activity: quantity_package.activities.first,
        external_reference: 'zone_formulas_de',
        kind: 'zone_activity'
      )
      expect_descriptor(project, expected_descriptor)
    end
  end

  def expect_descriptor(project, expected_descriptor)
    descriptor = described_class.new.project_descriptor(project)
    actual_descriptor = as_json(descriptor)
    puts JSON.generate(descriptor) if actual_descriptor != expected_descriptor

    expect(actual_descriptor).to eq(expected_descriptor)
  end

  def as_json(descriptor)
    JSON.parse(JSON.generate(descriptor))
  end
end
