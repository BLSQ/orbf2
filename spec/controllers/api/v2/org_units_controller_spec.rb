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

RSpec.describe Api::V2::OrgUnitsController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }
  let(:project) do
    project = build :project
    project.project_anchor = program.build_project_anchor(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  describe "#index" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before do
      stub_dhis2_orgunits_fetch(project)
      stub_dhis2_snapshot(project)
    end

    it "returns matching orgunits based on term" do
      get :index, params: { term: "arab", token: token }
      resp = JSON.parse(response.body)
      names = resp["data"].map { |h| h["attributes"]["displayName"] }
      expect(names).to eq(["Afro Arab Clinic", "Arab Clinic"])
    end

    it "returns matching orgunis based on id" do
      get :index, params: { id: "cDw53Ej8rju", token: token }
      resp = JSON.parse(response.body)
      names = resp["data"].map { |h| h["attributes"]["displayName"] }
      expect(names).to eq(["Afro Arab Clinic"])
    end

    it "returns empty array on 0 results" do
      get :index, params: { term: "nothing-here", token: token }
      resp = JSON.parse(response.body)
      expect(resp["data"]).to eq([])
    end

    it "returns everything without query parameters" do
      get :index, params: { token: token }
      resp = JSON.parse(response.body)
      expect(resp["data"].length).to be > 10
    end
  end
end
