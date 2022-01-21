# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::DeCocsController, type: :controller do
  include WebmockDhis2Helpers

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
      stub_all_data_compound(project)
      stub_dhis2_system_info_success(project.dhis2_url)
      Dhis2SnapshotWorker.new.perform(project.project_anchor_id, filter: ["data_elements"])
    end

    it "returns matching de based on term" do
      get :index, params: { term: "ANC 1st", token: token }
      resp = JSON.parse(response.body)
      puts(resp)
      names = resp["data"].map { |h| h["attributes"]["displayName"] }
      expect(names).to eq(["ANC 1st visit", "LLITN given at ANC 1st"])
    end

    it "returns matching de based on id" do
      get :index, params: { id: "fbfJHSPpUQD", token: token }
      resp = JSON.parse(response.body)
      names = resp["data"].map { |h| h["attributes"]["displayName"] }
      expect(names).to eq(["ANC 1st visit"])
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
