
require "rails_helper"

RSpec.describe Analytics::MultiEntitiesCalculator, type: :services do
  let(:calculator) { described_class.new(org_unit_ids, package, dhis2_values, period) }
  let(:org_unit_ids) { %w[dhis2_ou_1 dhis2_ou_2 dhis2_ou_3] }
  let(:dhis2_values) {
    [
      {
        org_unit:     "dhis2_ou_1",
        data_element: "dhis2_qty_1",
        period:       "2016Q2",
        value:        "1"
      },
      {
        org_unit:     "dhis2_ou_2",
        data_element: "dhis2_qty_1",
        period:       "2016Q2",
        value:        "2"
      },
      {
        org_unit:     "dhis2_ou_1",
        data_element: "dhis2_qty_2",
        period:       "2016Q2",
        value:        "3"
      },
      {
        org_unit:     "dhis2_ou_2",
        data_element: "dhis2_qty_2",
        period:       "2016Q2",
        value:        "4"
      }
    ].map { |v| OpenStruct.new(v) }
  }

  let(:package) do
    package = build(:package)
    price_state = package.package_states.build(state: State.new(name: "price")).state
    quantity_state = package.package_states.build(state: State.new(name: "declared")).state

    act_1 = package.activities.build(code: "act1", name: "act1")
    act_1.activity_states.build(state: price_state, formula: "10", kind: "formula")
    act_1.activity_states.build(state: quantity_state, external_reference: "dhis2_qty_1")

    act_2 = package.activities.build(code: "act2", name: "act2")
    act_2.activity_states.build(state: price_state, formula: "20", kind: "formula")
    act_2.activity_states.build(state: quantity_state, external_reference: "dhis2_qty_2")

    rule = package.rules.build(kind: Rule::RULE_TYPE_MULTI_ENTITIES)
    rule.formulas.build(code: "capped", expression: "price * declared")
    package
  end

  let(:period) { Periods.from_dhis2_period("201604") }

  it "should should generated results per orgunits and activity" do
    act1 = package.activities.first
    act2 = package.activities.last

    expect(calculator.calculate).to eq([
      {
        activity:    act1,
        org_unit_id: "dhis2_ou_1",
        solution:    { "declared" => 1, "price" => 10, "capped" => 10 }
      }, {
        activity:    act2,
        org_unit_id: "dhis2_ou_1",
        solution:    { "declared" => 3, "price" => 20, "capped" => 60 }
      }, {
        activity:    act1,
        org_unit_id: "dhis2_ou_2",
        solution:    { "declared" => 2, "price" => 10, "capped" => 20 }
      }, {
        activity:    act2,
        org_unit_id: "dhis2_ou_2",
        solution:    { "declared" => 4, "price" => 20, "capped" => 80 }
      }, {
        activity:    act1,
        org_unit_id: "dhis2_ou_3",
        solution:    { "declared" => 0, "price" => 10, "capped" => 0 }
      }, {
        activity:    act2,
        org_unit_id: "dhis2_ou_3",
        solution:    { "declared" => 0, "price" => 20, "capped" => 0 }
      }
    ].map { |v| Analytics::MultiEntitiesCalculator::MultiEntitiesResult.with(v) })
  end
end
