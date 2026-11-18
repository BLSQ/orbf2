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

  describe "#create_data_element" do
    before do
      project.project_anchor.update(token: token)
      authenticated
      allow(OutputDatasetWorker).to receive(:trigger_sync_for_project)
    end

    let(:data_element) do
      {
        name:            "#{activity.name} - #{activity_formula.code}",
        shortName:       "short - #{activity_formula.code}",
        code:            "#{activity.code}_#{activity_formula.code}",
        valueType:       "NUMBER",
        aggregationType: "SUM"
      }
    end
    let(:payload) do
      {
        data: {
          attributes: { formulaId: activity_formula.id, topicId: activity.id, dataElement: data_element }
        }
      }
    end

    def errors
      JSON.parse(response.body)["errors"].map { |error| error["detail"] }
    end

    def stub_created(code, id)
      stub_default_category_combo(project)
      stub_metadata_import(project)
      stub_data_element_by_code(project, code, id)
    end

    it "creates the data element in dhis2 and maps the formula of the topic to it" do
      stub_created(data_element[:code], "newDeId0001")

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:ok)
      attributes = JSON.parse(response.body)["data"]["attributes"]
      expect(attributes).to include(
        "kind"              => "activity",
        "formulaId"         => activity_formula.id.to_s,
        "topicId"           => activity.id.to_s,
        "externalReference" => "newDeId0001"
      )
      expect(activity_formula.formula_mappings.find_by!(activity: activity).external_reference).to eq("newDeId0001")
      expect(OutputDatasetWorker).to have_received(:trigger_sync_for_project).with(project)
    end

    it "maps a package formula, without topic" do
      stub_created("package_amount", "newDeId0002")
      attributes = { formulaId: package_formula.id, dataElement: data_element.merge(code: "package_amount") }
      package_payload = { data: { attributes: attributes } }

      post(:create_data_element, params: package_payload)

      expect(response).to have_http_status(:ok)
      attributes = JSON.parse(response.body)["data"]["attributes"]
      expect(attributes).to include("kind" => "package", "topicId" => nil, "externalReference" => "newDeId0002")
    end

    it "refuses an already mapped formula of the topic without creating the data element" do
      activity_formula.formula_mappings.create!(activity: activity, kind: "activity", external_reference: "existingDe1")

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:bad_request)
      expect(errors).to eq(["#{activity_formula.code} is already mapped for #{activity.code}"])
      expect(a_request(:post, /metadata/)).not_to have_been_made
    end

    it "allows the formula mapped for another topic" do
      other = package.activities.second
      activity_formula.formula_mappings.create!(activity: other, kind: "activity", external_reference: "otherDe0001")
      stub_created(data_element[:code], "newDeId0001")

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:ok)
    end

    it "gives the dhis2 refusal and maps nothing" do
      stub_default_category_combo(project)
      stub_metadata_import(project, body: refused_import_report("code already exists"))

      expect { post(:create_data_element, params: payload) }.not_to(change { FormulaMapping.count })

      expect(response).to have_http_status(:bad_request)
      expect(errors).to eq(["dhis2 refused the data element: code already exists"])
      expect(OutputDatasetWorker).not_to have_received(:trigger_sync_for_project)
    end

    it "requires the dhis2 user for the audit trail" do
      request.headers["X-Dhis2UserId"] = nil

      post(:create_data_element, params: payload)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
