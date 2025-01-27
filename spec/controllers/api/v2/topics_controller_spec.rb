# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::TopicsController, type: :controller do
  def ensure_json(payload)
    JSON.parse(JSON.generate(payload))
  end

  let(:token) { "123456789" }
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let(:project) { create :project, project_anchor: project_anchor }
  let(:package) { project.packages.create!(name: "HF quantity", kind: "single", frequency: "monthly", data_element_group_ext_ref: "healthfacilities") }

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
      ensure_json(
        data: {
          attributes: {
            name:      "Topic very long name",
            shortName: "Topic"
          }
        }
      )
    }
    it "create a topic" do
      post(:create, params: payload)

      resp = JSON.parse(response.body)

      expect(resp["data"]["type"]).to eq("topic")

      attributes = resp["data"]["attributes"]
      expect(attributes["code"]).to eq("topic_very_long_name")
      expect(attributes["name"]).to eq("Topic very long name")
      expect(attributes["shortName"]).to eq("Topic")

      expect(attributes["stableId"]).not_to be_nil
    end

    describe "on existing set" do
      it "create a topic and put it in an existing set" do
        payload["data"]["relationships"] = { "sets" => [{ "type" => "set", "id" => package.id.to_s }] }
        post(:create, params: payload)

        resp = JSON.parse(response.body)

        expect(resp["data"]["type"]).to eq("topic")

        attributes = resp["data"]["attributes"]
        expect(attributes["code"]).to eq("topic_very_long_name")
        expect(attributes["name"]).to eq("Topic very long name")
        expect(attributes["shortName"]).to eq("Topic")

        expect(attributes["stableId"]).not_to be_nil

        package.reload
        expect(package.activities.first.id.to_s).to eq(resp["data"]["id"])
      end
    end

    it "create a topic handles validation errors" do
      post(:create,
           params: payload)

      post(:create,
           params: payload)
      resp = JSON.parse(response.body)
      expect(resp).to eq("errors" => [
                           { "status"  => "400",
                             "message" => "Validation failed: Name has already been taken, Code has already been taken",
                             "details" => { "code" => ["has already been taken"], "name"=> ["has already been taken"]} }
                         ])
    end
  end

  describe "#create" do
    before do
      authenticated
    end
    let(:payload) {
      ensure_json(
        id:   activity.id,
        data: {
          attributes: {
            name:      "Topic very long name new",
            shortName: "Topic new",
            code:      "med_01"
          }
        }
      )
    }
    let(:activity) {
      project.activities.create!(name: "demo")
    }

    it "update a topic" do
      activity.reload

      put(:update, params: payload)

      resp = JSON.parse(response.body)

      expect(resp["data"]["type"]).to eq("topic")

      attributes = resp["data"]["attributes"]

      expect(attributes["code"]).to eq("med_01")
      expect(attributes["name"]).to eq("Topic very long name new")
      expect(attributes["shortName"]).to eq("Topic new")

      expect(attributes["stableId"]).to eq(activity.stable_id)
    end

    describe "on existing set" do
      let(:package2) { project.packages.create!(name: "HF quality", kind: "single", frequency: "quarterly", data_element_group_ext_ref: "healthfacilities") }

      it "update a topic" do
        package2.activities << activity

        activity.reload
        payload["data"]["relationships"] = { "sets" => [{ "type" => "set", "id" => package.id.to_s }] }

        put(:update, params: payload)

        resp = JSON.parse(response.body)

        expect(resp["data"]["type"]).to eq("topic")

        attributes = resp["data"]["attributes"]

        expect(attributes["code"]).to eq("med_01")
        expect(attributes["name"]).to eq("Topic very long name new")
        expect(attributes["shortName"]).to eq("Topic new")

        expect(attributes["stableId"]).to eq(activity.stable_id)

        package2.reload
        expect(package.activities.map(&:code)).not_to include(activity.code)
      end
    end

    it "update a topic handles validation errors" do
      payload["data"]["attributes"]["shortName"] = "super very veryveryveryveryveryveryveryveryveryveryveryveryvery long"
      put(:update, params: payload)

      resp = JSON.parse(response.body)
      expect(resp).to eq(
        "errors" => [
          { "details" => { "short_name"=>["is too long (maximum is 40 characters)"] },
            "message" => "Validation failed: Short name is too long (maximum is 40 characters)",
            "status"  => "400" }
        ]
      )
    end
  end
end
