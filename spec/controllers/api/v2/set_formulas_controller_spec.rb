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

RSpec.describe Api::V2::SetFormulasController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }

  let(:project_with_packages) do
    project = full_project
    project.project_anchor.update(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  def authenticated
    request.headers["Accept"] = "application/vnd.api+json;version=2"
    request.headers["X-Token"] = token
    request.headers["X-Dhis2UserId"] = "aze123sdf"
  end

  describe "#show" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before do
      authenticated
    end

    it "returns not found for non existing formula" do
      stub_all_pyramid(project_with_packages)

      package = project_with_packages.packages.first
      formula = package.package_rule.formulas.first

      get(:show, params: { set_id: package.id, id: "abdc123" })

      _resp = JSON.parse(response.body)
      expect(response.status).to eq(404)
    end

    it "returns formula data for existing formula" do
      stub_all_pyramid(project_with_packages)

      package = project_with_packages.packages.first
      formula = package.package_rule.formulas.first

      get(:show, params: { set_id: package.id, id: formula.id })

      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(formula.id.to_s)
      expect(resp["data"]["attributes"]["availableVariables"]).to eq(formula.rule.available_variables)
      expect(resp["data"]["attributes"]["mockValues"]).to eq({})
    end
  end
end
