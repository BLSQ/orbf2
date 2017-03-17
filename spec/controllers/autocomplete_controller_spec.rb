require "rails_helper"

RSpec.describe Setup::AutocompleteController, type: :controller do
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
    end

    it "should return all data_ements" do
      stub_request(:get, "#{project.dhis2_url}/api/dataElements?fields=:all&pageSize=50000")
        .to_return(status: 200, body: fixture_content(:dhis2, "all_data_elements.json"))

        stub_request(:get, "#{project.dhis2_url}/api/dataElementGroups?fields=:all&pageSize=50000")
          .to_return(status: 200, body: fixture_content(:dhis2, "data_element_groups.json"))

        stub_request(:get, "#{project.dhis2_url}/api/indicators?fields=:all&pageSize=50000")
            .to_return(status: 200, body: fixture_content(:dhis2, "indicators.json"))


      get :data_elements, params: { project_id: project.id }
    end
  end

  describe "When authenticated #orgunitgroup" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    it "should autocomplete by sibling_id" do
      project.create_entity_group(name: "Public Facilities", external_reference: "f25dqv3Y7Z0")

      stub_dhis2_all_orgunits
      stub_dhis2_all_orgunits_groups

      get :organisation_unit_group, params: { project_id: project.id, siblings: "true" }
      expect(JSON.parse(response.body)).to eq(
        [{ "type" => "option", "value" => "RXL3lPSK8oG", "label" => "Clinic" },
         { "type" => "option", "value" => "oRVt7g429ZO", "label" => "Public facilities" },
         { "type" => "option", "value" => "tDZVQ1WtwpA", "label" => "Hospital" },
         { "type" => "option", "value" => "EYbopBOJWsW", "label" => "MCHP" },
         { "type" => "option", "value" => "uYxK4wmcPqA", "label" => "CHP" },
         { "type" => "option", "value" => "CXw2yu5fodb", "label" => "CHC" },
         { "type" => "option", "value" => "gzcv65VyaGq", "label" => "Chiefdom" },
         { "type" => "option", "value" => "w1Atoz18PCL", "label" => "District" }]
      )
    end

    it "should autocomplete org unit groups by name" do
      stub_dhis2_all_orgunits_groups
      stub_dhis2_all_orgunits

      get :organisation_unit_group, params: { project_id: project.id, term: "cli" }
      options = JSON.parse(response.body)
      expect(options.size).to eq 14
      expect(options.first["type"]).to eq "option"
      expect(options.first["value"]).to eq "CXw2yu5fodb"
      expect(options.first["label"]).to include("CHC (194/1336)")

    end

    def stub_dhis2_all_orgunits_groups
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=id,displayName&pageSize=20000")
        .to_return(
          status: 200,
          body:   fixture_content(:dhis2, "organisationUnitGroups.json")
        )
    end

    def stub_dhis2_all_orgunits
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=id,displayName,organisationUnitGroups&pageSize=50000")
        .to_return(
          status: 200,
          body:   fixture_content(:dhis2, "all_organisation_units_with_groups.json")
        )
    end
  end
end
