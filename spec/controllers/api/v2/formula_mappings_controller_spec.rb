# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::FormulaMappingsController, type: :controller do
  include_context "basic_context"
  let(:token) { "123456789" }
  let(:project) { full_project }
  let(:package) { project.packages.first }
  let(:activity) { package.activities.first }

  let(:activity_formula) { package.activity_rule.formulas.first }
  let(:package_formula) { package.package_rule.formulas.first }

  def authenticated
    request.headers["Accept"] = "application/vnd.api+json;version=2"
    request.headers["X-Token"] = project.project_anchor.token
    request.headers["X-Dhis2UserId"] = "aze123sdf"
  end

  describe "#create activity" do
    before do
      project.project_anchor.update(token: token)
      authenticated
    end
    let(:payload) {
      {
        data: {
          attributes: {
            formulaId:         activity_formula.id,
            topicId:           activity.id,
            externalReference: "dhis2id.comboid"
          }
        }
      }
    }

    it "create a input mapping" do
      post(:create, params: payload)

      resp = JSON.parse(response.body)
      expect(resp["data"]["type"]).to eq("formulaMapping")
      attribs = resp["data"]["attributes"]
      expect(attribs["kind"]).to eq("activity")
      expect(attribs["formulaId"]).to eq(activity_formula.id.to_s)
      expect(attribs["topicId"]).to eq(activity.id.to_s)
      expect(attribs["externalReference"]).to eq("dhis2id.comboid")
    end
  end

  describe "#package rule" do
    before do
      project.project_anchor.update(token: token)
      authenticated
    end
    let(:payload) {
      {
        data: {
          attributes: {
            formulaId:         package_formula.id,
            externalReference: "dhis2id.comboid"
          }
        }
      }
    }
    it "create then update an input mapping" do
      post(:create, params: payload)

      resp = JSON.parse(response.body)
      expect(resp["data"]["type"]).to eq("formulaMapping")
      attribs = resp["data"]["attributes"]
      expect(attribs["kind"]).to eq("package")
      expect(attribs["formulaId"]).to eq(package_formula.id.to_s)
      expect(attribs["topicId"]).to eq(nil)
      expect(attribs["externalReference"]).to eq("dhis2id.comboid")

      update_payload = {
        id:   resp["data"]["id"],
        data: {
          attributes: {
            formulaId:         package_formula.id,
            externalReference: "newdhis2id.comboid"
          }
        }
      }

      put(:update, params: update_payload)

      resp = JSON.parse(response.body)
      attribs = resp["data"]["attributes"]
      expect(attribs["externalReference"]).to eq("newdhis2id.comboid")

      delete(:destroy, params: { id: resp["data"]["id"] })
    end
  end
end
