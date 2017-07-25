require "rails_helper"
require_relative "./dhis2_snapshot_fixture"

RSpec.describe InvoicesForEntitiesWorker do
  include Dhis2SnapshotFixture
  include_context "basic_context"

  let(:program) { create :program }

  let(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program

    with_activities_and_formula_mappings(project)
    create_snaphots(project)
    project
  end

  def with_last_year_verified_values(project)
    project.packages.first.activity_rule.formulas.create(
      code:        "verified_last_year_average",
      expression:  "avg(%{verified_previous_year_values})",
      description: "last year verified payment"
    )
    self
  end

  def with_cycle_values(project)
    project.packages.first.activity_rule.formulas.create(
      code:        "verified_current_cycle_average",
      expression:  "avg(%{verified_current_cycle_values})",
      description: "current cycle verified payment"
    )
    self
  end

  def with_monthly_payment_rule(project)
    payment_rule = project.payment_rules.create!(
      packages:        [project.packages[0], project.packages[2]],
      frequency:       "monthly",
      rule_attributes: {
        name:                "monthly payments",
        kind:                "payment",
        formulas_attributes: [
          {
            code:        "payment",
            expression:  "quantity_total_pma + quality_technical_score_value * (sum(quantity_total_pma, %{quantity_total_pma_values})) ",
            description: "doc monthly payment"
          }
        ]
      }
    )

    puts "added payment for  #{payment_rule.packages.map(&:name)}"

    self
 end

  def create_snaphots(project)
    return if project.project_anchor.dhis2_snapshots.any?
    stub_organisation_unit_group_sets(project)
    stub_organisation_unit_groups(project)

    stub_organisation_units(project)
    stub_data_elements(project)
    stub_data_elements_groups(project)
    stub_system_info(project)
    stub_indicators(project)

    Dhis2SnapshotWorker.new.perform(project.project_anchor.id)
    WebMock.reset!
  end

  it "should perform" do
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    stub_dhis2_values
    stub_export_values("invoice_zero_all.json")

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1)
  end

  it "should perform for subset of contracted_entities" do
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    stub_dhis2_values
    stub_export_values("invoice_zero_single.json")

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1, ["vRC0stJ5y9Q"])
  end

  it "should perform for yearly project cycle" do
    project.update_attributes(cycle: "yearly")
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    stub_dhis2_values_yearly("{}", "2015-01-01")
    stub_export_values("invoice_zero_single.json")

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1, ["vRC0stJ5y9Q"])
  end

  it "should perform for yearly project cycle and appropriate values" do
    project.update_attributes(cycle: "yearly")
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    with_last_year_verified_values(project)
    with_cycle_values(project)
    with_monthly_payment_rule(project)
    with_activities_and_formula_mappings(project)

    refs = project.activities
                  .flat_map(&:activity_states)
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort
    values = refs.each_with_index.map do |data_element, index|
      [{
        dataElement:          data_element,
        value:                index,
        period:               "2015",
        orgUnit:              "vRC0stJ5y9Q",
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }, (1..12).map do |month|
        {
          dataElement:          data_element,
          value:                index,
          period:               "2014#{month}",
          orgUnit:              "vRC0stJ5y9Q",
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end]
    end

    stub_dhis2_values_yearly(JSON.pretty_generate("dataValues": values.flatten), "2014-01-01")
    stub_export_values("invoice_yearly.json")

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1, ["vRC0stJ5y9Q"])
  end

  def stub_dhis2_values_yearly(values, start_date)
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=true&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=#{start_date}")
      .to_return(status: 200, body: values, headers: {})
  end

  def stub_dhis2_values(values = "")
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=true&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=2015-01-01")
      .to_return(status: 200, body: values, headers: {})
  end

  def stub_export_values(expected_fixture)
    puts "Stubbing dataValueSets with #{expected_fixture}"
    stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")
      .with(body: JSON.generate(JSON.parse(fixture_content(:scorpio, expected_fixture))))
      .to_return(status: 200, body: "", headers: {})
  end
end
