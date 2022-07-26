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

RSpec.describe Api::V2::TopicFormulasController, type: :controller do
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

  describe "#show" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "returns not found for non existing formula" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:show, params: { set_id: "123abcd", id: "abdc123" })
      _resp = JSON.parse(response.body)
      expect(response.status).to eq(404)
    end

    it "returns formula data for existing formula" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first
      formula = package.activity_rule.formula("quantity")

      get(:show, params: { set_id: package.id, id: formula.id })
      resp = JSON.parse(response.body)

      expect(resp["data"]["id"]).to eq(formula.id.to_s)
      expect(resp["data"]["attributes"]["availableVariables"]).to eq(formula.rule.available_variables)
      expect(resp["data"]["attributes"]["mockValues"]).to eq({})
      expect(resp["data"]["relationships"]["usedFormulas"]["data"][0]["id"]).to eq(formula.used_formulas.first.id.to_s)
      expect(resp["data"]["relationships"]["usedByFormulas"]["data"][0]["id"]).to eq(formula.used_by_formulas.first.id.to_s)

      record_json("set.json", resp)
    end
  end

  describe "#update" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "should return validation errors" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first
      formula = package.activity_rule.formula("quantity")

      put(:update, params: { set_id: package.id, id: formula.id, data: { id: formula.id, attributes: { code: "test_code", shortName: "new", description: "new desc", expression: "if( " } } })
      resp = JSON.parse(response.body)

      expect(resp).to eq({ "errors"=>[{ "details" => { "expression"=>["too many opening parentheses"] }, "message" => "Validation failed: Expression too many opening parentheses", "status" => "400" }] })
    end
  end

  describe "#create" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    it "should create a formula" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first

      post(:create, params: { set_id: package.id, data: { attributes: {
             code: "test_code",
             description: "test",
             shortName: "test",
             expression: "2+2",
           } } })

      resp = JSON.parse(response.body)
      attributes = resp["data"]["attributes"]

      expect(attributes["id"]).to_not be_nil
      expect(attributes["code"]).to eq("test_code")
      expect(attributes["description"]).to eq("test")
      expect(attributes["shortName"]).to eq("test")
      expect(attributes["expression"]).to eq("2+2")
    end

    it "should return validation errors" do
      stub_all_pyramid(project_with_packages)
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      package = project_with_packages.packages.first

      post(:create, params: { set_id: package.id, data: { attributes: {
             code: "test_code",
             shortName: "test",
             expression: "2+2",
           } } })

      resp = JSON.parse(response.body)

      expect(resp).to eq({"errors"=>[{"status"=>"400", "message"=>"Validation failed: Description can't be blank", "details"=>{"description"=>["can't be blank"]}}]})
    end
  end
end
