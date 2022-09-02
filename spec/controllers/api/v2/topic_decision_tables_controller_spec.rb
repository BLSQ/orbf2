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

RSpec.describe Api::V2::TopicDecisionTablesController, type: :controller do
  include_context "basic_context"
  include WebmockDhis2Helpers

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

  def authenticate
    request.headers["Accept"] = "application/vnd.api+json;version=2"
    request.headers["X-Token"] = project_with_packages.project_anchor.token
    request.headers["X-Dhis2UserId"] = "aze123sdf"
  end

  let(:package) do
    project_with_packages.packages.first
  end

  describe "#destroy" do
    let(:decision_table) do
      package.activity_rule.decision_tables.first
    end
    it "should delete the decision table" do
      authenticate

      delete(:destroy, params: {
               set_id: package.id,
               id:     decision_table.id
             })

      expect {
        decision_table.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#index" do
    it "should return the decision tables for the package" do
      authenticate

      get(:index, params: {
               set_id: package.id,
             })

      resp = JSON.parse(response.body)
      expect(resp["data"][0]["type"]).to eq("decisionTable")
    end
  end

  describe "#update" do
    let(:decision_table) do
      package.activity_rule.decision_tables.first
    end

    it "should verify authentication" do
      put(:update, params: {
            set_id: package.id,
            id:     decision_table.id,
            data:   {
              id:         decision_table.id,
              attributes: {
                name:        "test_newName",
                shortName:   "new",
                description: "new desc",
                expression:  "if( "
              }
            }
          })

      resp = JSON.parse(response.body)

      expect(resp).to eq({ "errors" => [{ "message" => "Unauthorized", "status" => "401" }] })
    end

    it "should update" do
      authenticate

      put(:update, params: {
            set_id: package.id,
            id:     decision_table.id,
            data:   {
              id:         decision_table.id,
              attributes: {
                name:        "test_newName",
                comment:     "new comment",
                startPeriod: "202101",
                endPeriod:   "202112",
                content:     [
                  "in:activity_code,out:bareme",
                  "*,45"
                ].join("\n")
              }
            }
          })

      resp = JSON.parse(response.body)

      expect(resp["data"]["attributes"]).to eq(
        {
          "comment"     => "new comment",
          "content"     => "in:activity_code,out:bareme\n*,45",
          "endPeriod"   => "202112",
          "inHeaders"   => ["activity_code"],
          "name"        => "test_newName",
          "outHeaders"  => ["bareme"],
          "sourceUrl"   => nil,
          "startPeriod" => "202101"

        }
      )
    end

    it "should return validation errors" do
      authenticate

      put(:update, params: {
            set_id: package.id,
            id:     decision_table.id,
            data:   {
              id:         decision_table.id,
              attributes: {
                name:        "test_newName",
                comment:     "new comment",
                startPeriod: "202101",
                endPeriod:   "202112",
                content:     [
                  "in:activity_code,out:bareme",
                  "unknown_activity_01,45"
                ].join("\n")
              }
            }
          })

      resp = JSON.parse(response.body)

      expect(resp).to eq(
        {
          "errors" => [
            { "details" => {
              "content" => ["{\"in:activity_code\"=>\"unknown_activity_01\", \"out:bareme\"=>\"45\"} not in available package codes [\"vaccination\", \"clients_sous_traitement_arv_suivi_pendant_les_6_premiers_mois\", \"*\"]!"]
            }, "message" => "Validation failed: Content {\"in:activity_code\"=>\"unknown_activity_01\", \"out:bareme\"=>\"45\"} not in available package codes [\"vaccination\", \"clients_sous_traitement_arv_suivi_pendant_les_6_premiers_mois\", \"*\"]!",
                "status" => "400" }
          ]
        }
      )
    end
  end

  describe "#create" do
    it "should return validation errors" do
      authenticate

      post(:create, params: {
             set_id: package.id,
             data:   {
               attributes: {
                 name:        "test_newName",
                 comment:     "new comment",
                 startPeriod: "202101",
                 endPeriod:   "202112",
                 content:     [
                   "in:activity_code,out:bareme",
                   "*,45"
                 ].join("\n")
               }
             }
           })

      resp = JSON.parse(response.body)

      expect(resp["data"]["attributes"]).to eq(
        {
          "comment"     => "new comment",
          "content"     => "in:activity_code,out:bareme\n*,45",
          "endPeriod"   => "202112",
          "inHeaders"   => ["activity_code"],
          "name"        => "test_newName",
          "outHeaders"  => ["bareme"],
          "sourceUrl"   => nil,
          "startPeriod" => "202101"
        }
      )
    end
  end
end
