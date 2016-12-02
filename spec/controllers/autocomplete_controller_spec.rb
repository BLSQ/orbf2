require "rails_helper"

RSpec.describe AutocompleteController, type: :controller do
  describe "When non authenticated #orgunitgroup" do
    it "should redirect to sign on" do
      get :organisation_unit_group, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #orgunitgroup" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    let(:project) do
      project = create :project
      user.project = project
      user.save!
      user.reload
      project
    end

    it "should autocomplete org unit groups by name" do
      stub_dhis2_all_orgunit_counts

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=id,name,displayName,organisationUnits~size~rename(orgunitscount)&filter=name:ilike:cli")
        .to_return(status: 200,
                   body:   fixture_content(:dhis2, "organisationUnitGroups-like-cli.json"))
      stub_dhis2_organisation_units_in_group_MAs88nJc9nL
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?filter=organisationUnitGroups.id:eq:MAs88nJc9nL&pageSize=5")
        .to_return(status: 200, body: fixture_content(:dhis2, "organizationUnits-in-group-MAs88nJc9nL.json"))

      get :organisation_unit_group, params: { project_id: project.id, term: "cli" }

      expect(assigns(:items).first).to eq(
        id:                       "RXL3lPSK8oG",
        organisation_units:       [
          { name: "Afro Arab Clinic" },
          { name: "Agape CHP" },
          { name: "Arab Clinic" },
          { name: "Blessed Mokaba clinic" },
          { name: "Bucksal Clinic" }
        ],
        organisation_units_count: "51",
        organisation_units_total: 1332,
        value:                    "Clinic"
      )
    end

    it "should autocomplete org unit groups by id" do
      stub_dhis2_all_orgunit_counts

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=id,name,displayName,organisationUnits~size~rename(orgunitscount)&filter=id:eq:RXL3lPSK8oG")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))

      stub_dhis2_organisation_units_in_group_MAs88nJc9nL

      get :organisation_unit_group, params: { project_id: project.id, id: "RXL3lPSK8oG" }

      expect(assigns(:items).first).to eq(
        id:                       "RXL3lPSK8oG",
        organisation_units:       [
          { name: "Afro Arab Clinic" },
          { name: "Agape CHP" },
          { name: "Arab Clinic" },
          { name: "Blessed Mokaba clinic" },
          { name: "Bucksal Clinic" }
        ],
        organisation_units_count: "51",
        organisation_units_total: 1332,
        value:                    "Clinic"
      )
    end

    def stub_dhis2_organisation_units_in_group_MAs88nJc9nL
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?filter=organisationUnitGroups.id:eq:RXL3lPSK8oG&pageSize=5")
        .to_return(status: 200, body: fixture_content(:dhis2, "organizationUnits-in-group-RXL3lPSK8oG.json"))
    end

    def stub_dhis2_all_orgunit_counts
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnits.json"))
    end
  end
end
