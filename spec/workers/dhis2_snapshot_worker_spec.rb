# frozen_string_literal: true

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
    stub_organisation_unit_group_sets(project)
    stub_organisation_unit_groups(project)
    stub_organisation_units(project)
    stub_data_elements(project)
    stub_data_elements_groups(project)
    stub_system_info(project)
    stub_indicators(project)
    stub_category_combos(project)

    expect(Dhis2Snapshot.all.count).to eq 0

    previous_snapshot = project_anchor.dhis2_snapshots.find_or_initialize_by(
      kind:          "organisation_units",
      month:         Time.new.month,
      year:          Time.new.year,
      dhis2_version: "2.24",
      job_id:        "rspec",
      content:       []
    )

    previous_snapshot.save!

    Dhis2SnapshotWorker.new.perform(project_anchor.id, disable_tracking: false)
    expect(Dhis2Snapshot.all.count).to eq Dhis2Snapshot::KINDS.size

    Dhis2SnapshotWorker.new.perform(project_anchor.id)
    expect(Dhis2Snapshot.all.count).to eq Dhis2Snapshot::KINDS.size

    pyramid = project_anchor.pyramid_for(Time.now)
    expect(pyramid.org_units.size).to eq 1332
    expect(pyramid.org_unit_groups.size).to eq 18

    data_compound = project_anchor.data_compound_for(Time.now)
    expect(data_compound.data_elements.size).to eq 875
    expect(data_compound.data_element_groups.size).to eq 93
  end

  describe "active regions" do
    FIELDS = "?fields=:all,!coordinates,!ancestors,!access,!attributeValues,"\
                "!users,!dataSets,!userGroupAccesses,!dimensionItemType,!externalAccess"
    let(:target_group_id) { "targetgroupid" }
    let(:pager) {
      {
        page_count: 1,
        page:       1
      }
    }

    it "capture only active regions" do
      project

      project.create_entity_group!(
        external_reference:              target_group_id,
        name:                            "Target Group",
        limit_snaphot_to_active_regions: true
      )

      stub_system_info(project)
      stub_entity_group
      stub_country
      stub_region("TEQlaapDQoK", "region1")
      stub_region("qhqAxPSTUXp", "region2")

      expect(Dhis2Snapshot.all.count).to eq 0

      Dhis2SnapshotWorker.new.perform(project_anchor.id, filter: ["organisation_units"])
      expect(Dhis2Snapshot.all.count).to eq 1
      expect(Dhis2Snapshot.all.last.content.map { |it| it["table"]["id"] }).to eq(%w[TEQlaapDQoK qhqAxPSTUXp ImspTQPwCqd])
    end

    def stub_entity_group
      stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnitGroups"\
        "?fields=organisationUnits%5Bpath%5D&filter=id:eq:" + target_group_id)
        .to_return(status: 200,
                   body:   JSON.pretty_generate(
                     "organisationUnitGroups": [
                       {
                         "organisationUnits": [
                           {
                             "path": "/ImspTQPwCqd/TEQlaapDQoK/pRHGAROvuyI/EURoFVjowXs"
                           },
                           {
                             "path": "/ImspTQPwCqd/qhqAxPSTUXp/J4GiUImJZoE/NMcx2jmra3c"
                           }
                         ]
                       }
                     ]
                   ))
    end

    def stub_region(id, name)
      stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnits" +
                          FIELDS +
                          "&filter=path:like:/ImspTQPwCqd/" + id +
                          "&pageSize=5000")
        .to_return(
          status: 200,
          body:   JSON.pretty_generate(
            pager:             pager,
            organisationUnits: [
              { id: id, name: name }
            ]
          )
        )
    end

    def stub_country
      stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnits" +
                          FIELDS +
                          "&filter=path:eq:/ImspTQPwCqd&pageSize=5000")
        .to_return(
          status: 200,
          body:   JSON.pretty_generate(
            pager:             pager,
            organisationUnits: [
              { id: "ImspTQPwCqd", name: "country" }
            ]
          )
        )
    end
  end
end
