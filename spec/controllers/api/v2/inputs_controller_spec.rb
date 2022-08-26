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

RSpec.describe Api::V2::InputsController, type: :controller do
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

  describe "#create" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "should create the state for the package and the project" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first

      post(:create, params: { set_id: package.id, data: { attributes: {
             name:      "test",
             shortName: "test"
           } } })

      resp = JSON.parse(response.body)
      id = resp["data"]["id"]
      name = resp["data"]["attributes"]["name"]

      package.reload
      project_with_packages.reload

      expect(id).to_not be_nil
      expect(name).to eq("test")
      expect(package.states.last.id.to_s).to eq(id)
      expect(project_with_packages.states.last.id.to_s).to eq(id)
    end

    it "should return validation errors" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first
      state = package.states.first

      post(:create, params: { set_id: package.id, data: { attributes: {
             name:      state.name,
             shortName: state.short_name
           } } })

      resp = JSON.parse(response.body)

      expect(resp).to eq({ "errors"=>[{ "status" => "400", "message" => "Validation failed: Name state name should be unique per project", "details" => { "name"=>["state name should be unique per project"] } }] })
    end
  end
end
