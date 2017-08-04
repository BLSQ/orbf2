require "rails_helper"

RSpec.describe Dhis2AnalyticsWorker do
  include_context "basic_context"

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
      publish_date: Time.current - 2.days,
      status:       "published"
    )
  end

  it "should run analytics on the project DHIS2" do
    project
    stub_analytics(project)

    Dhis2AnalyticsWorker.new.perform(project.id)
  end

  def stub_analytics(project)
    stub_request(:post, "#{project.dhis2_url}/api/resourceTables")
      .to_return(status: 200, body: fixture_content(:dhis2, "analytics.json"))
  end
end
