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
    request.headers["X-Dhis2UserId"] = "aze123sdf"
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
          { "details" => { "state_id"=>["has already been taken"], "external_reference"=>["has already been taken"] },
            "message" => "Validation failed: External reference has already been taken, State has already been taken",
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

  describe "#create_data_element" do
    before do
      authenticated
      allow(SynchroniseDegDsWorker).to receive(:perform_async)
    end

    let(:data_element) do
      {
        name:            "Topic 1 - declared",
        shortName:       "Topic 1 - declared",
        code:            "topic_01_declared",
        valueType:       "NUMBER",
        aggregationType: "SUM"
      }
    end
    let(:payload) { { topic_id: activity.id, data: { attributes: { code: state.code, dataElement: data_element } } } }

    def errors
      JSON.parse(response.body)["errors"].map { |error| error["detail"] }
    end

    it "creates the data element in dhis2 and maps it to the state" do
      stub_default_category_combo(project)
      stub_metadata_import(project)
      stub_data_element_by_code(project, "topic_01_declared", "newDeId0001")

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:ok)
      attributes = JSON.parse(response.body)["data"]["attributes"]
      expect(attributes).to include(
        "name"              => "Topic 1 - declared",
        "kind"              => "data_element",
        "origin"            => "dataValueSets",
        "externalReference" => "newDeId0001"
      )
      mapping = activity.activity_states.find_by!(state: state)
      expect(mapping.external_reference).to eq("newDeId0001")
      expect(SynchroniseDegDsWorker).to have_received(:perform_async).with(project.project_anchor.id)
    end

    it "refuses an already mapped state without creating the data element" do
      activity.activity_states.create!(state: state, name: "existing", kind: "data_element",
                                       origin: "dataValueSets", external_reference: "existingDe1")

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:bad_request)
      expect(errors).to eq(["#{state.code} is already mapped for topic_01"])
      expect(a_request(:post, /metadata/)).not_to have_been_made
    end

    it "refuses an unknown state" do
      post(:create_data_element, params: payload.deep_merge(data: { attributes: { code: "nope" } }))

      expect(response).to have_http_status(:bad_request)
      expect(errors).to eq(["unknown state nope"])
    end

    it "gives the dhis2 refusal and maps nothing" do
      stub_default_category_combo(project)
      stub_metadata_import(project, body: refused_import_report("code already exists"))

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:bad_request)
      expect(errors).to eq(["dhis2 refused the data element: code already exists"])
      expect(activity.activity_states).to be_empty
      expect(SynchroniseDegDsWorker).not_to have_received(:perform_async)
    end

    it "requires the dhis2 user for the audit trail" do
      request.headers["X-Dhis2UserId"] = nil

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
