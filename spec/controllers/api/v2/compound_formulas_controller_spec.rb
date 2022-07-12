# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::CompoundFormulasController, type: :controller do
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

    it "returns not found for non existing compound" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:show, params: { compound_id: "abdc123", id: "123abcd" })
      _resp = JSON.parse(response.body)
      expect(response.status).to eq(404)
    end

    it "returns formula for existing compound" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      payment_rule = project_with_packages.payment_rules.first
      formula = payment_rule.rule.formulas.first
      get(:show, params: { compound_id: payment_rule.id, id: formula.id })
      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(formula.id.to_s)
      expect(resp["data"]["attributes"]["availableVariables"]).to eq(formula.rule.available_variables)
      expect(resp["data"]["attributes"]["mockValues"]).to eq({})
      record_json("compound.json", resp)
    end
  end
end
