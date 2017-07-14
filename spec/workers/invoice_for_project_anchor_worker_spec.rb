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
    project
  end

  def create_snaphots
    project
    stub_organisation_unit_group_sets
    stub_organisation_unit_groups
    stub_organisation_units
    stub_data_elements
    stub_data_elements_groups
    stub_system_info
    stub_indicators
    Dhis2SnapshotWorker.new.perform(project.project_anchor.id)
  end

  it "should perform" do
    create_snaphots
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    stub_dhis2_values
    stub_export_values

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1)
  end

  it "should perform for subset of contracted_entities" do
    create_snaphots
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    stub_dhis2_values
    stub_export_values_limited

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1, ["vRC0stJ5y9Q"])
  end

  it "should perform for yearly project cycle" do
    create_snaphots
    project.update_attributes(cycle: "yearly")
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    stub_dhis2_values_yearly
    stub_export_values_limited

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1, ["vRC0stJ5y9Q"])
  end

  it "should perform for yearly project cycle and appropriate values" do
    create_snaphots
    project.update_attributes(cycle: "yearly")
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!

    project.packages.each do |package|
      package.states.each do |state|
        package.activities.each_with_index do |activity, index|
          activity_state = activity.activity_states.find_by(state: state)
          next if activity_state
          activity.activity_states.create!(
            state:              state,
            name:               "#{activity.name}-#{state.code}",
            external_reference: "ref--#{activity.name}-#{state.code}"
          )
        end
      end
    end

    project.activities
           .flat_map(&:activity_states)
           .sort_by(&:name)
           .each_with_index do |as, index|
      as.external_reference = "ref-#{index}"
      as.save!
    end

    refs = project.activities
                  .flat_map(&:activity_states)
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort
    values = refs.each_with_index.map do |data_element, index|
      {
        dataElement:          data_element,
        value:                index,
        period:               "2015",
        orgUnit:              "vRC0stJ5y9Q",
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }
    end

    stub_dhis2_values_yearly(JSON.pretty_generate("dataValues": values))
    stub_export_values_limited

    InvoiceForProjectAnchorWorker.new.perform(project.project_anchor.id, 2015, 1, ["vRC0stJ5y9Q"])
  end

  def stub_dhis2_values_yearly(values = "")
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=true&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=2015-01-01")
      .to_return(status: 200, body: values, headers: {})
  end

  def stub_dhis2_values(values = "")
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=true&endDate=2015-03-31&orgUnit=vRC0stJ5y9Q&startDate=2015-01-01")
      .to_return(status: 200, body: values, headers: {})
  end

  def stub_export_values_limited
    stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")
      .with(body: JSON.generate(
        "dataValues" => [
          { "dataElement" => "ext-attributed_points", "orgUnit" => "vRC0stJ5y9Q", "period" => "2015Q1", "value" => "0.0", "comment" => "P-attributed_points-Quality" },
          { "dataElement" => "ext-max_points", "orgUnit" => "vRC0stJ5y9Q", "period" => "2015Q1", "value" => "0.0", "comment" => "P-max_points-Quality" },
          { "dataElement" => "ext-quality_technical_score_value", "orgUnit" => "vRC0stJ5y9Q", "period" => "2015Q1", "value" => 0, "comment" => "P-quality_technical_score_value-Quality" }
        ]
      )).to_return(status: 200, body: "", headers: {})
  end

  def stub_export_values
    stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")
      .with(body:
                  JSON.generate(
                    "dataValues" => [
                      { "dataElement" => "ext-attributed_points", "orgUnit" => "bM4Ky73uMao", "period" => "2015Q1", "value" => "0.0", "comment" => "P-attributed_points-Quality" },
                      { "dataElement" => "ext-max_points", "orgUnit" => "bM4Ky73uMao", "period" => "2015Q1", "value" => "0.0", "comment" => "P-max_points-Quality" },
                      { "dataElement" => "ext-quality_technical_score_value", "orgUnit" => "bM4Ky73uMao", "period" => "2015Q1", "value" => 0, "comment" => "P-quality_technical_score_value-Quality" },
                      { "dataElement" => "ext-attributed_points", "orgUnit" => "jk1TtiBM5hz", "period" => "2015Q1", "value" => "0.0", "comment" => "P-attributed_points-Quality" },
                      { "dataElement" => "ext-max_points", "orgUnit" => "jk1TtiBM5hz", "period" => "2015Q1", "value" => "0.0", "comment" => "P-max_points-Quality" },
                      { "dataElement" => "ext-quality_technical_score_value", "orgUnit" => "jk1TtiBM5hz", "period" => "2015Q1", "value" => 0, "comment" => "P-quality_technical_score_value-Quality" },
                      { "dataElement" => "ext-attributed_points", "orgUnit" => "uROAmk9ymNE", "period" => "2015Q1", "value" => "0.0", "comment" => "P-attributed_points-Quality" },
                      { "dataElement" => "ext-max_points", "orgUnit" => "uROAmk9ymNE", "period" => "2015Q1", "value" => "0.0", "comment" => "P-max_points-Quality" },
                      { "dataElement" => "ext-quality_technical_score_value", "orgUnit" => "uROAmk9ymNE", "period" => "2015Q1", "value" => 0, "comment" => "P-quality_technical_score_value-Quality" },
                      { "dataElement" => "ext-attributed_points", "orgUnit" => "vRC0stJ5y9Q", "period" => "2015Q1", "value" => "0.0", "comment" => "P-attributed_points-Quality" },
                      { "dataElement" => "ext-max_points", "orgUnit" => "vRC0stJ5y9Q", "period" => "2015Q1", "value" => "0.0", "comment" => "P-max_points-Quality" },
                      { "dataElement" => "ext-quality_technical_score_value", "orgUnit" => "vRC0stJ5y9Q", "period" => "2015Q1", "value" => 0, "comment" => "P-quality_technical_score_value-Quality" }
                    ]
                  ))
      .to_return(status: 200, body: "", headers: {})
  end
end
