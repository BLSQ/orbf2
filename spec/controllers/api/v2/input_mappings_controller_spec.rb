# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::InputMappingsController, type: :controller do
  let(:token) { "123456789" }
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let(:project) { create :project, project_anchor: project_anchor }
  let(:activity) { create :activity, project: project, name: "Topic 1", code: "topic_01" }
  let(:state) { create :state, project: project, name: "declared" }

  def authenticated
    request.headers["Accept"] = "application/vnd.api+json;version=2"
    request.headers["X-Token"] = project.project_anchor.token
  end

  describe "#create" do
    before do
      authenticated
    end
    let(:payload) {
      {
        topic_id: activity.id,
        data:     {
          attributes: {
            code:              state.code,
            formula:           nil,
            name:              "sample",
            origin:            "dataValueSets",
            kind:              "data_element",
            externalReference: "dhis2id"
          }
        }
      }
    }
    it "create a input mapping" do
      post(:create, params: payload)

      resp = JSON.parse(response.body)

      expect(resp["data"]["type"]).to eq("inputMapping")

      attributes = resp["data"]["attributes"]

      expect(attributes["name"]).to eq("sample")
      expect(attributes["origin"]).to eq("dataValueSets")
      expect(attributes["kind"]).to eq("data_element")

      expect(attributes["externalReference"]).to eq("dhis2id")

      expect(attributes["stableId"]).not_to be_nil
      expect(attributes["formula"]).to be_nil
    end

    it "create a input mapping handles validation errors" do
      post(:create,
           params: payload)

      post(:create,
           params: payload)
      resp = JSON.parse(response.body)
      expect(resp).to eq(
        "errors" => [
          { "details" => { "state_id"=>["has already been taken"] },
            "message" => "Validation failed: State has already been taken",
            "status"  => "400" }
        ]
      )
    end
  end

  describe "#update" do
    before do
      authenticated
    end

    let(:payload) {
      {
        topic_id: activity.id,
        id:       activit_state.id,
        data:     {
          attributes: {
            code:              state.code,
            formula:           nil,
            name:              "sample",
            origin:            "dataValueSets",
            kind:              "data_element",
            externalReference: "dhis2id"
          }
        }
      }
    }

    let(:activit_state) {
      activity.activity_states.create!(
        name:               "sample",
        origin:             "analytics",
        kind:               "data_element",
        external_reference: "dhis2id",
        state_id:           state.id
      )
    }

    it "update an input mapping" do
      put(:update, params: payload)
      resp = JSON.parse(response.body)
      expect(resp["data"]["attributes"]["origin"]).to eq("dataValueSets")
    end

    it "update handle validation errors" do
      payload[:data][:attributes][:origin] = "badOrigin"
      put(:update, params: payload)
      resp = JSON.parse(response.body)
      expect(resp).to eq(
        "errors" => [
          {
            "status"  => "400",
            "message" => "Validation failed: Origin badOrigin is not a valid see dataValueSets,analytics",
            "details" => { "origin" => ["badOrigin is not a valid see dataValueSets,analytics"] }
          }
        ]
      )
    end
  end
end
