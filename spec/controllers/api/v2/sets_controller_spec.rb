# frozen_string_literal: true

require "rails_helper"

def stub_dhis2_orgunits_fetch(project)
  stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
    .to_return(
      status: 200,
      body:   fixture_content(:dhis2, "all_organisation_units_with_groups.json")
    )
end

def stub_dhis2_snapshot(project)
  stub_dhis2_system_info_success(project.dhis2_url)
  Dhis2SnapshotWorker.new.perform(project.project_anchor_id, filter: ["organisation_units"])
end

RSpec.describe Api::V2::SetsController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }

  let(:project_without_packages) do
    project = build :project
    project.project_anchor = program.build_project_anchor(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  let(:project_with_packages) do
    project = full_project
    project.project_anchor.update(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  describe "#index" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "returns empty array for project without packages" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:index, params: {})
      resp = JSON.parse(response.body)
      expect(resp["data"]).to eq([])
    end

    it "returns all packages for project with packages" do
      stub_all_pyramid(project_with_packages)
      stub_dhis2_all_orgunits_groups(project_with_packages)
      stub_dhis2_orgunits_fetch(project_with_packages)
      stub_dhis2_snapshot(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      get(:index, params: {})
      resp = JSON.parse(response.body)

      expect(resp["data"].length).to be > 0
      expect(resp["data"].length).to eq(project_with_packages.packages.length)
      record_json("sets.json", resp)
    end
  end

  describe "#show" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "returns not found for non existing set" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:show, params: { id: "abdc123" })
      _resp = JSON.parse(response.body)
      expect(response.status).to eq(404)
    end

    it "returns set data for existing set" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first
      get(:show, params: { id: package.id })
      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(package.id.to_s)
      record_json("set.json", resp)
    end
  end
end
