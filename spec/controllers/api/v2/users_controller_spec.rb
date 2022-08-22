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

  describe "#index" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    it "should only return users in the same program" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token

      create(:user, program_id: user.program_id)
      create(:user, program_id: create(:program).id)

      get(:index)

      resp = JSON.parse(response.body)

      expect(resp["data"].length).to eq(2);
    end
  end

  describe "#update" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end
  end
end