# frozen_string_literal: true

require "rails_helper"
require_relative "./dhis2_snapshot_fixture"

RSpec.describe InvoiceForProjectAnchorWorker do
  include Dhis2SnapshotFixture
  include_context "basic_context"

  ORG_UNIT_ID = "vRC0stJ5y9Q"

  let(:program) { create :program }

  let!(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program

    with_activities_and_formula_mappings(project)
    create_snaphots(project)
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!
    project
  end

  let(:worker) { described_class.new }

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
          value:                100 + (index % 2),
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

    Dhis2SnapshotWorker.new.perform(project.project_anchor.id)
    WebMock.reset!
  end

  describe "throttled" do
    it 'defaults to 3 concurrent' do
      expect(Sidekiq::Throttled::Registry.get(InvoiceForProjectAnchorWorker).concurrency.limit).to eq(3)
    end

    it 'can be overridden with env' do
      skip("The `load` resets the code coverage, this test will pass but code coverage is incorrect")
      current_env = ENV["SDKQ_MAX_CONCURRENT_INVOICE"]
      ENV["SDKQ_MAX_CONCURRENT_INVOICE"] = "10"
      # Force a reload of the file to update throttled settings
      load File.join(Rails.root, "app/workers/invoice_for_project_anchor_worker.rb")
      expect(Sidekiq::Throttled::Registry.get(InvoiceForProjectAnchorWorker).concurrency.limit).to eq(10)
      if current_env
        ENV["SDKQ_MAX_CONCURRENT_INVOICE"] = current_env
      else
        ENV.delete("SDKQ_MAX_CONCURRENT_INVOICE")
      end
    end
  end

  it "should NOT on non contracted entities" do
    project.entity_group.external_reference = "external_reference"
    project.entity_group.save!

    fetch_values_request = stub_dhis2_values
    export_request = stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")

    worker.perform(project.project_anchor.id, 2015, 1)

    expect(fetch_values_request).to have_been_made.times(0)
    expect(export_request).to have_been_made.times(0)
  end

  it "should perform for subset of contracted_entities" do
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=2015-01-01")
      .to_return(status: 200, body: "", headers: {})

    export_request = stub_export_values("invoice_zero_single.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID, ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  it "should perform for packages and payments quarterly" do
    project.payment_rules.each { |p| p.update(frequency: "quarterly") }
    project.packages.each { |p| p.update(frequency: "quarterly") }

    with_activities_and_formula_mappings(project)

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=#{ORG_UNIT_ID}&startDate=2015-01-01")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": generate_quarterly_values_for(project)))

    export_request = stub_export_values("invoice_quarterly.json")

    worker.perform(project.project_anchor.id, 2015, 1)

    expect(export_request).to have_been_made.once
  end

  it "should support formula with parent levels" do
    population_state = project.states.create!(name: "population")
    package = project.packages.first
    package.states.push(population_state)
    formula = package.activity_rule.formulas.create(
      code:        "sample_parent_values",
      description: "sample_parent_values",
      expression:  "verified / population_level_1"
    )
    with_activities_and_formula_mappings(project)

    org_unit_values = generate_quarterly_values_for(project)

    refs = project.activities
                  .flat_map(&:activity_states)
                  .select { |activity_state| activity_state.state == population_state }
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort

    org_unit_level_1_values = refs.map do |external_reference|
      {
        dataElement:          external_reference,
        value:                123,
        period:               "2015",
        orgUnit:              "ImspTQPwCqd",
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }
    end

    Rails.logger.info "org_unit_level_1_values #{org_unit_level_1_values.to_json}"
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=#{ORG_UNIT_ID}&startDate=2015-01-01")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": (org_unit_values + org_unit_level_1_values)))

    export_request = stub_export_values("invoice_with_parent.json")
    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  it "should perform for yearly project cycle" do
    project.update(cycle: "yearly")

    stub_dhis2_values_yearly("{}", "2015-01-01")
    export_request = stub_export_values("invoice_zero_single.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  it "should perform for yearly project cycle and appropriate values" do
    project.update(cycle: "yearly")

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
        orgUnit:              ORG_UNIT_ID,
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }, (1..12).map do |month|
        {
          dataElement:          data_element,
          value:                index,
          period:               "2014#{month}",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end]
    end

    stub_dhis2_values_yearly(JSON.pretty_generate("dataValues": values.flatten), "2014-01-01")
    export_request = stub_export_values("invoice_yearly.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  it "should perform for sub contracted entities pattern" do
    with_multi_entity_rule(project)
    with_activities_and_formula_mappings(project)

    expect(project.packages.first.activity_rule.available_variables).to include(
      "org_units_count",
      "org_units_sum_if_count"
    )

    refs = project.activities
                  .flat_map(&:activity_states)
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort
    values = refs.each_with_index.flat_map do |data_element, index|
      [{
        dataElement:          data_element,
        value:                index,
        period:               "2015",
        orgUnit:              ORG_UNIT_ID,
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }, (1..12).map do |month|
        {
          dataElement:          data_element,
          value:                index,
          period:               "2015#{month}",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end, (1..12).map do |month|
        {
          dataElement:          data_element,
          value:                index,
          period:               "2015#{month}",
          orgUnit:              "PMa2VCrupOd",
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end]
    end

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&dataSet=ds-2&endDate=2015-12-31&orgUnit=XJ6DqDkMlPv&startDate=2015-01-01")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": values.flatten))

    export_request = stub_export_values("invoice_multi_entities.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  describe "new engine" do
    let(:org_unit_ids) do
      %w[AhnK8hb3JWm BLVKubgVxkF Bift1B4gjru Bq5nb7UAEGd C9uduqDZr9d DSBXsRQSXUW DmaLM8WYmWv ENHOJz3UH5L Ea3j0kUvyWg EmTN0L4EAVi GvFqTavdpGE HPg74Rr7UWp IXJg79fclDm ImspTQPwCqd JLKGG67z7oj JNJIPX9DfaW KIUCimTXf8Q KKkLOTpMXGV KuR0y0h0mOM LV2b3vaLRl1 LaxJ6CD2DHq Ls2ESQONh9S M2qEv692lS6 M721NHGtdZV O6uvpzGd5pu OuwX8H2CcRO PD1fqyvJssC PLoeN9CaL7z PMa2VCrupOd PQZJPIpTepd Qw7c6Ckb0XC QywkxFudXrC RUCp6OaTSAD T2Cn45nBY0u TEQlaapDQoK TQkG0sX9nca U6Kr7Gtpidn Uo4cyJwAhTW VCtF1DbspR5 VGAFxBXz16y Vnc2qIRLbyw Vth0fbpFcsO W5fN3G6y1VI XEyIRFd9pct XJ6DqDkMlPv at6UHUQatSo bM4Ky73uMao bPHn9IgjKLC bVZTNrnfn9G cDw53Ej8rju cM2BKSrj9F9 cZtKKa9eJZ3 cgqkFdShPzg ctfiYW0ePJ8 eIQbndfxQMb fXT1scbEObM fdc6uOvgoji gmen7SXL9CU jCnyQOKQBFX jUb8gELQApl jmIPBj66vD6 kBP1UvZpsNj kJq2mPyFEHo kLNQT4KQ9hT kMTHqMgenme lc3eMKXaEfw mTNOoGXuC39 nCh5dBoJVNw nV3OkyzF4US nq7F0t1Pz6t qhqAxPSTUXp qtr8GGlm4gg roQ2l7TX0eZ tHUYjt9cU6h u6ZGNI8yUmt uNEhNuBUr0i vRC0stJ5y9Q vn9KJsLyP5f vv1QJFONsT6 wNYYRm2c9EK wicmjKI3xiP yP2nhllbQPh]
    end
    let(:dataset_ext_ids) { ["ds-0", "ds-1", "ds-2"] }
    let(:periods) { %w[2014July 2015 201501 201502 201503 2015Q1] }

    it "should perform for sub contracted entities pattern with new engine" do
      with_new_engine(project)

      with_multi_entity_rule(project)
      with_activities_and_formula_mappings(project)

      expect(project.packages.first.activity_rule.available_variables).to include(
        "org_units_count",
        "org_units_sum_if_count"
      )

      refs = project.activities
                    .flat_map(&:activity_states)
                    .map(&:external_reference)
                    .uniq
                    .reject(&:empty?).sort
      values = refs.each_with_index.flat_map do |data_element, index|
        [{
          dataElement:          data_element,
          value:                index,
          period:               "2015",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              ORG_UNIT_ID,
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              "PMa2VCrupO",
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end]
      end

      org_unit_ids.each_slice(50).each do |org_unit_ids_slice|
        orgunit_values = values.flatten.select { |v| org_unit_ids_slice.include?(v[:orgUnit]) }
        stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?" +
          dataset_ext_ids.each_with_index.map { |de, i| "#{i == 0 ? '' : '&'}dataSet=#{de}" }.join +
          periods.map { |pe| "&period=#{pe}" }.join +
          org_unit_ids_slice.map { |id| "&orgUnit=#{id}" }.join +
          "&children=false")
          .to_return(status: 200, body: JSON.pretty_generate("dataValues": orgunit_values))
      end

      export_request = stub_export_values("invoice_multi_entities_new_engine.json")

      worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

      expect(export_request).to have_been_made.once
    end
  end

  describe "new engine" do
    let(:org_unit_ids) do
      %w[AhnK8hb3JWm BLVKubgVxkF Bift1B4gjru Bq5nb7UAEGd C9uduqDZr9d DSBXsRQSXUW DmaLM8WYmWv ENHOJz3UH5L Ea3j0kUvyWg EmTN0L4EAVi GvFqTavdpGE HPg74Rr7UWp IXJg79fclDm ImspTQPwCqd JLKGG67z7oj JNJIPX9DfaW KIUCimTXf8Q KKkLOTpMXGV KuR0y0h0mOM LV2b3vaLRl1 LaxJ6CD2DHq Ls2ESQONh9S M2qEv692lS6 M721NHGtdZV O6uvpzGd5pu OuwX8H2CcRO PD1fqyvJssC PLoeN9CaL7z PMa2VCrupOd PQZJPIpTepd Qw7c6Ckb0XC QywkxFudXrC RUCp6OaTSAD T2Cn45nBY0u TEQlaapDQoK TQkG0sX9nca U6Kr7Gtpidn Uo4cyJwAhTW VCtF1DbspR5 VGAFxBXz16y Vnc2qIRLbyw Vth0fbpFcsO W5fN3G6y1VI XEyIRFd9pct XJ6DqDkMlPv at6UHUQatSo bM4Ky73uMao bPHn9IgjKLC bVZTNrnfn9G cDw53Ej8rju cM2BKSrj9F9 cZtKKa9eJZ3 cgqkFdShPzg ctfiYW0ePJ8 eIQbndfxQMb fXT1scbEObM fdc6uOvgoji gmen7SXL9CU jCnyQOKQBFX jUb8gELQApl jmIPBj66vD6 kBP1UvZpsNj kJq2mPyFEHo kLNQT4KQ9hT kMTHqMgenme lc3eMKXaEfw mTNOoGXuC39 nCh5dBoJVNw nV3OkyzF4US nq7F0t1Pz6t qhqAxPSTUXp qtr8GGlm4gg roQ2l7TX0eZ tHUYjt9cU6h u6ZGNI8yUmt uNEhNuBUr0i vRC0stJ5y9Q vn9KJsLyP5f vv1QJFONsT6 wNYYRm2c9EK wicmjKI3xiP yP2nhllbQPh]
    end
    let(:dataset_ext_ids) { ["ds-0", "ds-1", "ds-2"] }
    let(:periods) { %w[2014July 2015 201501 201502 201503 2015Q1] }

    it "should perform for sub contracted entities pattern with new engine" do
      with_latest_engine(project)

      with_multi_entity_rule(project)
      with_activities_and_formula_mappings(project)

      expect(project.packages.first.activity_rule.available_variables).to include(
        "org_units_count",
        "org_units_sum_if_count"
      )

      refs = project.activities
                    .flat_map(&:activity_states)
                    .map(&:external_reference)
                    .uniq
                    .reject(&:empty?).sort
      values = refs.each_with_index.flat_map do |data_element, index|
        [{
          dataElement:          data_element,
          value:                index,
          period:               "2015",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              ORG_UNIT_ID,
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              "PMa2VCrupO",
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end]
      end

      org_unit_ids.each_slice(50).each do |org_unit_ids_slice|
        orgunit_values = values.flatten.select { |v| org_unit_ids_slice.include?(v[:orgUnit]) }
        stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?" +
          dataset_ext_ids.each_with_index.map { |de, i| "#{i == 0 ? '' : '&'}dataSet=#{de}" }.join +
          periods.map { |pe| "&period=#{pe}" }.join +
          org_unit_ids_slice.map { |id| "&orgUnit=#{id}" }.join +
          "&children=false")
          .to_return(status: 200, body: JSON.pretty_generate("dataValues": orgunit_values))
      end

      export_request = stub_export_values("invoice_multi_entities_new_engine_v3.json")

      worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

      expect(export_request).to have_been_made.once
    end
  end

  def with_latest_engine(project)
    project.update!(engine_version: 3)
    project
  end

  def with_new_engine(project)
    project.update!(engine_version: 2)
    project
  end

  def stub_dhis2_values_yearly(values, start_date)
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=#{start_date}")
      .to_return(status: 200, body: values)
  end

  def stub_dhis2_values(values = "")
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=2015-01-01")
      .to_return(status: 200, body: values)
  end

  def stub_export_values(expected_fixture)
    Rails.logger.info "Stubbing dataValueSets with #{expected_fixture}"
    stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")
      .with { |request|
      fixture_values = sorted_datavalues(JSON.parse(fixture_content(:scorpio, expected_fixture)))
      values = sorted_datavalues(JSON.parse(request.body))
      fixture_values == values
    }
      .to_return(status: 200, body: "")
  end

  def sorted_datavalues(json)
    sorted = json["dataValues"].sort_by { |e| [e["dataElement"], e["orgUnit"], e["period"]] }
    # Rails.logger.info "sorted\n #{sorted}\n\n\n"
    sorted
  end
end
