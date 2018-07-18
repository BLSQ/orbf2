require "rails_helper"

RSpec.describe Setup::AutocompleteController, type: :controller do
  include WebmockDhis2Helpers

  describe "When non authenticated #orgunitgroup" do
    it "should redirect to sign on" do
      get :organisation_unit_group, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  let(:program) { create :program }

  let(:project) do
    project = build :project
    project.project_anchor = program.build_project_anchor
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  describe "When authenticated #data_ements" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
      stub_all_data_compound(project)
    end

    it "should return all data_ements" do
      get :data_elements, params: { project_id: project.id }
    end

    it "should return for including name" do
      stub_dhis2_snapshot
      get :data_elements, params: { project_id: project.id, term: "flaccid" }
      expect(assigns(:items).map { |i| i[:label] }.uniq).to eq(
        [
          "Accute Flaccid Paralysis (Deaths < 5 yrs)",
          "Acute Flaccid Paralysis (AFP) follow-up",
          "Acute Flaccid Paralysis (AFP) new",
          "Acute Flaccid Paralysis (AFP) referrals"
        ]
      )
    end

    it "should return empty array if non existing id" do
      get :data_elements, params: { project_id: project.id, id: "unknownid" }
      expect(response.body).to eq "[]"
    end

    it "should return for a single element if existing id" do
      stub_dhis2_snapshot
      get :data_elements, params: { project_id: project.id, id: "FTRrcoaog83" }
      expect(assigns(:items).map { |i| i[:label] }).to eq ["Accute Flaccid Paralysis (Deaths < 5 yrs)"]
    end

    def stub_dhis2_snapshot
      stub_dhis2_system_info_success(project.dhis2_url)
      Dhis2SnapshotWorker.new.perform(project.project_anchor_id, filter: ["data_elements"])
    end
  end

  describe "When authenticated #indicators" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    it "should autocomplete indicators" do
      stub_all_data_compound(project)
      get :indicators, params: { project_id: project.id, term: "cli" }
    end
  end

  describe "When authenticated #organisation_units" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    it "should return matching orgunits" do
      stub_dhis2_all_orgunits(project)

      stub_dhis2_snapshot
      get :organisation_units, params: { project_id: project.id, term: "arab" }
      expect(assigns(:items).map { |i| i[:label] }.uniq).to eq(
        ["Afro Arab Clinic", "Arab Clinic"]
      )
    end

    def stub_dhis2_snapshot
      stub_dhis2_system_info_success(project.dhis2_url)
      Dhis2SnapshotWorker.new.perform(project.project_anchor_id, filter: ["organisation_units"])
    end

    def stub_dhis2_all_orgunits(project)
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=:all&pageSize=50000")
        .to_return(
          status: 200,
          body:   fixture_content(:dhis2, "all_organisation_units_with_groups.json")
        )
    end
  end

  describe "When authenticated #orgunitgroup" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    it "should return empty when no params" do
      stub_dhis2_all_orgunits(project)
      stub_dhis2_all_orgunits_groups(project)

      get :organisation_unit_group, params: { project_id: project.id }
      expect(JSON.parse(response.body).size).to eq 0
    end

    it "should autocomplete by sibling_id" do
      project.create_entity_group(name: "Public Facilities", external_reference: "f25dqv3Y7Z0")

      stub_all_pyramid(project)

      get :organisation_unit_group, params: { project_id: project.id, siblings: "true" }

      expect(response.body).to eq('[{"type":"option","value":"RXL3lPSK8oG","id":"RXL3lPSK8oG","label":"Clinic"},{"type":"option","value":"oRVt7g429ZO","id":"oRVt7g429ZO","label":"Public facilities"},{"type":"option","value":"tDZVQ1WtwpA","id":"tDZVQ1WtwpA","label":"Hospital"},{"type":"option","value":"EYbopBOJWsW","id":"EYbopBOJWsW","label":"MCHP"},{"type":"option","value":"uYxK4wmcPqA","id":"uYxK4wmcPqA","label":"CHP"},{"type":"option","value":"CXw2yu5fodb","id":"CXw2yu5fodb","label":"CHC"},{"type":"option","value":"gzcv65VyaGq","id":"gzcv65VyaGq","label":"Chiefdom"},{"type":"option","value":"w1Atoz18PCL","id":"w1Atoz18PCL","label":"District"},{"type":"option","value":"J40PpdN4Wkk","id":"J40PpdN4Wkk","label":"Northern Area"},{"type":"option","value":"jqBqIXoXpfy","id":"jqBqIXoXpfy","label":"Southern Area"},{"type":"option","value":"b0EsAxm8Nge","id":"b0EsAxm8Nge","label":"Western Area"},{"type":"option","value":"nlX2VoouN63","id":"nlX2VoouN63","label":"Eastern Area"}]')
    end

    it "should autocomplete org unit groups by name" do
      stub_all_pyramid(project)

      get :organisation_unit_group, params: { project_id: project.id, term: "cli" }
      options = JSON.parse(response.body)
      expect(options.size).to eq 18
      expect(options.first["type"]).to eq "option"
      expect(options.first["value"]).to eq "CXw2yu5fodb"
      expect(options.first["label"]).to include("CHC (194/1332)")
    end
  end
end
