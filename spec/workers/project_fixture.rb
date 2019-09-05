# frozen_string_literal: true

require_relative "./dhis2_snapshot_fixture"
module ProjectFixture
  include Dhis2SnapshotFixture

  ORG_UNIT_ID = "vRC0stJ5y9Q"

  def with_latest_engine(project)
    project.update!(engine_version: 3)
    project
  end

  def with_new_engine(project)
    project.update!(engine_version: 2)
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

    Rails.logger.info "added payment for  #{payment_rule.packages.map(&:name)}"

    self
  end

  def with_multi_entity_rule(project)
    package = project.packages.first

    package.update!(ogs_reference: "J5jldMd8OHv", kind: "multi-groupset")
    package.package_states.each_with_index do |package_state, index|
      package_state.update!(ds_external_reference: "ds-#{index}")
    end
    rule = package.rules.create!(name: "multi-entities test", kind: "multi-entities")
    rule.decision_tables.create!(
      content: fixture_content(:scorpio, "decision_table_multi_entities.csv")
    )

    package.activity_rule.formulas.create!(
      code:        "org_units_count_exported",
      description: "org_units_count_exported",
      expression:  "org_units_count"
    )

    package.activity_rule.formulas.create!(
      code:        "org_units_sum_if_count_exported",
      description: "org_units_sum_if_count_exported",
      expression:  "org_units_sum_if_count"
    )
  end

  def generate_quarterly_values_for(project)
    refs = project.activities
                  .flat_map(&:activity_states)
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort
    values = refs.each_with_index.map do |data_element, index|
      [(1..4).map do |quarter|
        {
          dataElement:          data_element,
          value:                (100 + (index % 2)).to_s,
          period:               "2015Q#{quarter}",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end]
    end

    values.flatten
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
    stub_category_combos(project)

    Dhis2SnapshotWorker.new.perform(project.project_anchor.id)
    WebMock.reset!
  end
end
