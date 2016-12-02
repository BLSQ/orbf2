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

    let(:expected_group) do
      {
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
      }
    end

    it "should autocomplete org unit groups by name" do
      stub_dhis2_all_orgunit_counts
      stub_dhis2_organisation_unit_groups_like "cli"
      stub_dhis2_organisation_units_with_group_id "MAs88nJc9nL"
      stub_dhis2_organisation_units_with_group_id "RXL3lPSK8oG"

      get :organisation_unit_group, params: { project_id: project.id, term: "cli" }

      expect(assigns(:items).first).to eq(expected_group)
    end

    it "should autocomplete org unit groups by id" do
      stub_dhis2_all_orgunit_counts
      stub_dhis2_organisation_units_groups_with_counts_by_id "RXL3lPSK8oG"
      stub_dhis2_organisation_units_with_group_id "RXL3lPSK8oG"

      get :organisation_unit_group, params: { project_id: project.id, id: "RXL3lPSK8oG" }

      expect(assigns(:items).first).to eq(expected_group)
    end

    def stub_dhis2_organisation_unit_groups_like(term)
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?" \
      "fields=id,name,displayName,organisationUnits~size~rename(orgunitscount)"\
      "&filter=name:ilike:#{term}")
        .to_return(
          status: 200,
          body:   fixture_content(:dhis2, "organisationUnitGroups-like-cli.json")
        )
    end

    def stub_dhis2_organisation_units_groups_with_counts_by_id(group_id)
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?" \
        "fields=id,name,displayName,organisationUnits~size~rename(orgunitscount)"\
        "&filter=id:eq:#{group_id}")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))
    end

    def stub_dhis2_organisation_units_with_group_id(group_id)
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?"\
        "filter=organisationUnitGroups.id:eq:#{group_id}&pageSize=5")
        .to_return(
          status: 200,
          body:   fixture_content(:dhis2, "organizationUnits-in-group-#{group_id}.json")
        )
    end

    def stub_dhis2_all_orgunit_counts
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnits")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnits.json"))
    end
  end
end
