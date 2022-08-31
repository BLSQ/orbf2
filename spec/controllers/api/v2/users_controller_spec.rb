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

RSpec.describe Api::V2::UsersController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }

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

  def authenticated
    request.headers["Accept"] = "application/vnd.api+json;version=2"
    request.headers["X-Token"] = project_with_packages.project_anchor.token
  end

  describe "#index" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
      authenticated
    end

    it "should only return users in the same program" do
      create(:user, program_id: user.program_id)
      create(:user, program_id: create(:program).id)

      get(:index)

      resp = JSON.parse(response.body)

      expect(resp["data"].length).to eq(2);
    end
  end

  describe "#create" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
      authenticated
    end

    it "should create a new user" do
      post(:create, params: { data: { attributes: {
        email:        "testcreate@test.com",
        dhis2UserRef: "testuserref123"
      } } })

      resp = JSON.parse(response.body)
      attributes = resp["data"]["attributes"]

      expect(attributes["dhis2UserRef"]).to eq("testuserref123")
      expect(attributes["email"]).to eq("testcreate@test.com")
    end

    it "should return validation errors" do
      post(:create, params: { data: { attributes: {
        email:        "",
        dhis2UserRef: "testuserref123",
      } } })

      resp = JSON.parse(response.body)

      expect(resp["errors"][0]["message"]).to eq("Validation failed: Email can't be blank")
    end
  end

  describe "#update" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
      authenticated
    end

    it "should update user attrs" do
      other_user = create(:user, program_id: user.program_id)

      put(:update, params: { id: other_user.id, data: { attributes: {
        email:        "testupdate@test.com",
        dhis2UserRef: "testupdateuserref123"
      } } })
      
      resp = JSON.parse(response.body)
      attributes = resp["data"]["attributes"]

      expect(attributes["dhis2UserRef"]).to eq("testupdateuserref123")
    end
  end
end
