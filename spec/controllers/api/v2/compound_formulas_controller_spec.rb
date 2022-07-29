# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::CompoundFormulasController, type: :controller do
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

    before do
      authenticated
    end

    it "returns not found for non existing compound" do

      get(:show, params: { compound_id: project_with_packages.payment_rules.first.id, id: "123abcd" })

      _resp = JSON.parse(response.body)
      expect(response.status).to eq(404)
    end

    it "returns formula for existing compound" do
      payment_rule = project_with_packages.payment_rules.first
      formula = payment_rule.rule.formulas.first

      get(:show, params: { compound_id: payment_rule.id, id: formula.id })

      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(formula.id.to_s)
      expect(resp["data"]["attributes"]["availableVariables"]).to eq(formula.rule.available_variables)
      expect(resp["data"]["attributes"]["mockValues"]).to eq({})
    end
  end
end
