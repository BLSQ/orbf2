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
    %w[claimed declared tarif].each do |state_name|
      project.states.build(name: state_name)
    end
    project.project_anchor.update(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project.create_entity_group(external_reference: "external_reference", name: "main group")
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

  describe "#create" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "should create basic set (no main entity groups, no target entity groups)" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token

      post(:create, params: { data: { attributes: {
            name:               "azeaze",
            stateIds:           [],
            frequency:          "monthly",
            kind:               "zone",
            groupSetsExtRefs:   %w[groupsets_ext_ref1 groupsets_ext_ref2],
            includeMainOrgUnit: false
        } } })

      resp = JSON.parse(response.body)
      attributes = resp["data"]["attributes"]
      expect(resp["data"]["id"]).to_not be_nil
      expect(attributes["name"]).to eq("azeaze")
    end

    it "should return validation errors" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token

      post(:create, params: { data: { attributes: {
            name:               "",
            stateIds:           [],
            frequency:          "monthly",
            kind:               "zone",
            groupSetsExtRefs:   %w[groupsets_ext_ref1 groupsets_ext_ref2],
            includeMainOrgUnit: false
        } } })

      resp = JSON.parse(response.body)
      expect(resp).to eq({"errors"=>[{"status"=>"400", "message"=>"Validation failed: Name can't be blank", "details"=>{"name"=>["can't be blank"]}}]})
    end

    it "should create set with main entity groups, without target entity groups" do
    end

    it "should create set with main entity groups and target entity groups" do
      # to do 
    end
  end

  describe "#update" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "updates the state ids" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      package = project_with_packages.packages.first
      unused_project_states = project_with_packages.states.where.not(name: package.states.pluck(:name))
      state_ids = unused_project_states[0..1].pluck(:id).map(&:to_s)
      put(:update, params: { id: package.id, data: { attributes: {
        stateIds: state_ids,
      } } })

      package.reload

      package_state_ids = package.states.pluck(:id).map(&:to_s)
      state_ids.each do |id|
        expect(package_state_ids.include?(id)).to eq(true)
      end
    end

    it "updates the topic ids" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      package = project_with_packages.packages.first
      project_with_packages.activities.create!(name: "new activity", short_name: "new activity", code: "new_activity") 
      unused_project_topics = project_with_packages.activities.where.not(id: package.activities.pluck(:id))
      topic_ids = unused_project_topics.pluck(:id).map(&:to_s)

      put(:update, params: { id: package.id, data: { attributes: {
        topicIds: topic_ids,
      } } })

      package.reload
      
      package_activity_ids = package.activities.pluck(:id).map(&:to_s)
      topic_ids.each do |id|
        expect(package_activity_ids.include?(id)).to eq(true)
      end
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
      # various formulas have the formula type
      %w[topicFormulas setFormulas zoneTopicFormulas zoneFormulas multiEntitiesFormulas].each do |formula_type|
        types = resp["data"]["relationships"][formula_type]["data"].map { |f| f["type"] }.uniq
        if types.any?
          expect(types).to eq(["formula"])
        end
      end
      record_json("set.json", resp)
    end
  end
end
