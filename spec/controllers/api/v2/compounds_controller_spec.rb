# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::CompoundsController, type: :controller do
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

    it "returns empty array for project without payment rules" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:index, params: {})
      resp = JSON.parse(response.body)
      expect(resp["data"]).to eq([])
    end

    it "returns all payment rules for project with payment rules" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      get(:index, params: {})
      resp = JSON.parse(response.body)
      expect(resp["data"].length).to be > 0
      expect(resp["data"].length).to eq(project_with_packages.payment_rules.length)
      record_json("compounds.json", resp)
    end
  end

  describe "#show" do
    include_context "basic_context"

    it "returns not found for non existing compound" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:show, params: { id: "abdc123" })
      _resp = JSON.parse(response.body)
      expect(response.status).to eq(404)
    end

    it "returns set data for existing compound" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      payment_rule = project_with_packages.payment_rules.first
      get(:show, params: { id: payment_rule.id })
      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(payment_rule.id.to_s)
      expect(resp["data"]["relationships"]["sets"]["data"].uniq.length).to eq(2)
      expect(resp["included"].select { |r| r["type"] == "set"}.length).to eq(4)
      record_json("compound.json", resp)
    end
  end

  describe "#create" do
    include_context "basic_context"

    it "should create payment rule and associated rule" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      rule_count_before = Rule.all.count
      payment_rule_count_before = PaymentRule.all.count
      post(:create, params: { data: { attributes: { name: "new payment rule", frequency: "quarterly", setIds: project_with_packages.packages.pluck(:id).map(&:to_s) }}})
      resp = JSON.parse(response.body)
      attrs = resp["data"]["attributes"]
      expect(attrs["name"]).to eq("new payment rule")
      expect(Rule.all.count).to eq rule_count_before + 1
      expect(PaymentRule.all.count).to eq payment_rule_count_before + 1
    end

    it "should return validation errors" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      post(:create, params: { data: { attributes: { name: "new payment rule", frequency: "invalid", setIds: project_with_packages.packages.pluck(:id).map(&:to_s) }}})
      resp = JSON.parse(response.body)
      expect(resp["errors"][0]).to eq({"status"=>"400", "message"=>"Validation failed: Frequency invalid is not a valid see monthly,quarterly", "details"=>{"frequency"=>["invalid is not a valid see monthly,quarterly"]}})
    end
  end
end
