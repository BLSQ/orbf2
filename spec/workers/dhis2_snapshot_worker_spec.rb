require "rails_helper"
require_relative "./dhis2_snapshot_fixture"

RSpec.describe Dhis2SnapshotWorker do
  include_context "basic_context"
  include Dhis2SnapshotFixture
  let(:program) do
    Program.create(code: "siera")
  end

  let(:project_anchor) do
    program.create_project_anchor
  end

  let(:project) do
    project_anchor.projects.create!(
      name:         "sample",
      dhis2_url:    "http://play.dhis2.org/demo",
      user:         "admin",
      password:     "district",
      bypass_ssl:   false,
      publish_date: Time.now - 2.days,
      status:       "published"
    )
  end

  it "should perform organisation_units and organisation_unit_groups snapshot and update existing when run twice" do
    project
    stub_organisation_unit_groups
    stub_organisation_units
    stub_data_elements
    stub_data_elements_groups
    stub_system_info
    stub_indicators

    expect(Dhis2Snapshot.all.count).to eq 0

    Dhis2SnapshotWorker.new.perform(project_anchor.id)
    expect(Dhis2Snapshot.all.count).to eq 5

    Dhis2SnapshotWorker.new.perform(project_anchor.id)
    expect(Dhis2Snapshot.all.count).to eq 5

    pyramid = project_anchor.pyramid_for(Time.now)
    expect(pyramid.org_units.size).to eq 1336
    expect(pyramid.org_unit_groups.size).to eq 14

    data_compound = project_anchor.data_compound_for(Time.now)
    expect(data_compound.data_elements.size).to eq 875
    expect(data_compound.data_element_groups.size).to eq 93
  end
end
