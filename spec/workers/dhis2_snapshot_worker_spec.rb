require "rails_helper"

RSpec.describe Dhis2SnapshotWorker do
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
    stub_system_info

    expect(Dhis2Snapshot.all.count).to eq 0

    Dhis2SnapshotWorker.new.perform(project_anchor.id)

    expect(Dhis2Snapshot.all.count).to eq 2

    Dhis2SnapshotWorker.new.perform(project_anchor.id)

    expect(Dhis2Snapshot.all.count).to eq 2
  end


  def stub_system_info
    stub_request(:get, "#{project.dhis2_url}/api/system/info")
      .to_return(status: 200, body: '{"version":"1.0"}')
  end

  def stub_organisation_units
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=:all&pageSize=50000")
      .to_return(status: 200, body: '{"pager":{"page":1,"pageCount":1,"total":1332,"pageSize":50000},"organisationUnits":[]}')
  end

  def stub_organisation_unit_groups
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&pageSize=50000").
      to_return(:status => 200, :body => '{"pager":{"page":1,"pageCount":1,"total":1332,"pageSize":50000},"organisationUnitGroups":[]}', :headers => {})

  end
end
