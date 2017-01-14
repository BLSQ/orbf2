require "rails_helper"

RSpec.describe AutocompleteController, type: :controller do
  describe "When non authenticated #orgunitgroup" do
    it "should redirect to sign on" do
      get :organisation_unit_group, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  let(:program) { create :program }

  let(:project) do
    project = build :project
    project.program = program
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
      stub_request(:get, "#{project.dhis2_url}/api/dataElements?fields=id,displayName&pageSize=20000")
        .to_return(status: 200, body: fixture_content(:dhis2, "all_data_elements.json"))

      get :data_elements, params: { project_id: project.id }
    end
  end

  describe "When authenticated #orgunitgroup" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      sign_in user
    end

    let(:expected_group) do
      [
        { type: "option", value: "CXw2yu5fodb", label: "CHC (0/50) : ,..." },
        { type: "option", value: "gzcv65VyaGq", label: "Chiefdom (0/50) : ,..." },
        { type: "option", value: "uYxK4wmcPqA", label: "CHP (0/50) : ,..." },
        { type: "option", value: "RXL3lPSK8oG", label: "Clinic (0/50) : ,..." },
        { type: "option", value: "RpbiCJpIYEj", label: "Country (0/50) : ,..." },
        { type: "option", value: "w1Atoz18PCL", label: "District (0/50) : ,..." },
        { type: "option", value: "tDZVQ1WtwpA", label: "Hospital (0/50) : ,..." },
        { type: "option", value: "EYbopBOJWsW", label: "MCHP (0/50) : ,..." },
        { type: "option", value: "w0gFTTmsUcF", label: "Mission (0/50) : ,..." },
        { type: "option", value: "PVLOW4bCshG", label: "NGO (0/50) : ,..." },
        { type: "option", value: "MAs88nJc9nL", label: "Private Clinic (0/50) : ,..." },
        { type: "option", value: "oRVt7g429ZO", label: "Public facilities (0/50) : ,..." },
        { type: "option", value: "GGghZsfu7qV", label: "Rural (0/50) : ,..." },
        { type: "option", value: "f25dqv3Y7Z0", label: "Urban (0/50) : ,..." }
      ]
    end

    it "should autocomplete by sibling_id" do
      project.create_entity_group(name: "Public Facilities", external_reference: "f25dqv3Y7Z0")

      stub_dhis2_all_orgunits
      stub_dhis2_all_orgunits_groups

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&"\
              "filter=id:in:%5BRXL3lPSK8oG,oRVt7g429ZO,tDZVQ1WtwpA,EYbopBOJWsW,uYxK4wmcPqA,CXw2yu5fodb,gzcv65VyaGq,w1Atoz18PCL%5D"\
              "&pageSize=8")
        .to_return(status: 200, body: fixture_content(:dhis2, "sibling_org_unit_groups.json"))

      get :organisation_unit_group, params: { project_id: project.id, siblings: "true" }

      expect(assigns(:items)).to eq(

      )
    end

    it "should autocomplete org unit groups by name" do
      stub_dhis2_all_orgunits_groups
      stub_dhis2_all_orgunits

      get :organisation_unit_group, params: { project_id: project.id, term: "cli" }

      expect(assigns(:items).first).to eq(expected_group.first)
    end

    it "should autocomplete org unit groups by id" do
      stub_dhis2_all_orgunits_groups
      stub_dhis2_all_orgunits

      get :organisation_unit_group, params: { project_id: project.id, id: "RXL3lPSK8oG" }

      expect(assigns(:items).first).to eq(expected_group[1])
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
          body:   fixture_content(:dhis2, "organisationUnits.json")
        )
    end

    # def stub_dhis2_organisation_unit_groups_like(term)
    #   stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?" \
    #   "fields=id,name,displayName,organisationUnits~size~rename(orgunitscount)"\
    #   "&filter=name:ilike:#{term}")
    #     .to_return(
    #       status: 200,
    #       body:   fixture_content(:dhis2, "organisationUnitGroups-like-cli.json")
    #     )
    # end
    #
    # def stub_dhis2_organisation_units_groups_with_counts_by_id(group_id)
    #   stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?" \
    #     "fields=id,name,displayName,organisationUnits~size~rename(orgunitscount)"\
    #     "&filter=id:eq:#{group_id}")
    #     .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))
    # end
    #
    # def stub_dhis2_organisation_units_with_group_id(group_id)
    #   stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?"\
    #     "filter=organisationUnitGroups.id:eq:#{group_id}&pageSize=5")
    #     .to_return(
    #       status: 200,
    #       body:   fixture_content(:dhis2, "organizationUnits-in-group-#{group_id}.json")
    #     )
    # end
    #
    # def stub_dhis2_all_orgunit_counts
    #   stub_request(:get, "#{project.dhis2_url}/api/organisationUnits")
    #     .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnits.json"))
    # end
  end
end
