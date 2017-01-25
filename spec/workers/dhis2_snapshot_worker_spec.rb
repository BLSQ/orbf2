require "rails_helper"

RSpec.describe Dhis2SnapshotWorker do
  let(:program) do
    Program.create(code: "siera")
  end

  let(:project_anchor) do
    program.create_project_anchor
  end

  let(:project) do
    Project.create!(
      dhis2_url:  "http://play.dhis2.org/demo",
      user:       "admin",
      password:   "district",
      bypass_ssl: false
    )
  end
  it "should perform organisation_units snapshot" do
    Dhis2SnapshotWorker.new.perform(project_anchor.id, "organisation_units")
  end
end
