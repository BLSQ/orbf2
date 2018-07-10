require "rails_helper"

RSpec.describe Setup::InvoicesController, type: :controller do
  include WebmockDhis2Helpers

  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:org_unit_id) { "cDw53Ej8rju" }

    it "displays the form for entities" do
      get :new, params: { project_id: full_project.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:invoicing_request)).not_to be nil
    end

    it "schedule worker when push_to_dhis2 clicked" do
      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:         org_unit_id,
          year:           "2017",
          quarter:        "1",
          engine_version: "0"
        },
        push_to_dhis2:     true
      }
      expect(InvoiceForProjectAnchorWorker).to have_enqueued_sidekiq_job(full_project.project_anchor.id, "2017", "1", [org_unit_id])
    end

    it "calculate invoices" do
      stub_all_pyramid(full_project)
      stub_all_data_compound(full_project)
      stub_data_value_sets

      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:         org_unit_id,
          year:           "2017",
          quarter:        "1",
          engine_version: "1"
        },
        simulate_draft:    true
      }

      expect(response).to have_http_status(:success)
    end

    it "calculate invoices with new engine" do
      stub_new_pyramid
      stub_all_data_compound(full_project)
      stub_data_value_sets_for_new_engine

      verif_state = full_project.states.find { |s| s.name == "Verified" }
      maxscore_state = full_project.states.find { |s| s.name == "Max. Score" }
      full_project.activities.first.activity_states.create(
        [
          { name: "Vaccination Verified ", state: verif_state, formula: "0", kind: "formula" },
          { name: "Vaccination max ", state: maxscore_state, formula: "0", kind: "formula" }
        ]
      )

      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:         org_unit_id,
          year:           "2017",
          quarter:        "1",
          engine_version: "2"
        },
        simulate_draft:    true
      }

      expect(assigns(:invoicing_request).invoices.size).to eq(5)

      expect(response).to have_http_status(:success)
    end

    it "calculate invoices with mock_values" do
      stub_all_pyramid(full_project)
      stub_all_data_compound(full_project)

      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:         org_unit_id,
          year:           "2017",
          quarter:        "1",
          mock_values:    "1",
          engine_version: "1"
        },
        simulate_draft:    true
      }

      expect(response).to have_http_status(:success)
    end

    def stub_data_value_sets
      stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2017-12-31&orgUnit=#{org_unit_id}&startDate=2017-01-01")
        .to_return(status: 200, body: "")
    end

    def stub_data_value_sets_for_new_engine
      stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false" \
        "&orgUnit=ImspTQPwCqd&orgUnit=at6UHUQatSo&orgUnit=cDw53Ej8rju&orgUnit=qtr8GGlm4gg" \
        "&period=2017&period=201701&period=201702&period=201703&period=2017Q1")
        .to_return(status: 200, body: "")
    end

    def stub_new_pyramid
      stub_request(:get, "#{full_project.dhis2_url}/api/organisationUnits?fields=id,displayName,path,organisationUnitGroups&pageSize=40000")
        .to_return(status: 200, body: fixture_content(:dhis2, "all_organisation_units_with_groups.json"))

      stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnitGroups?fields=id,code,shortName,displayName&pageSize=40000")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))

      stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnitGroupSets?fields=id,code,shortName,displayName,organisationUnitGroups&pageSize=40000")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisation_unit_group_sets.json"))

      stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&orgUnit=cDw53Ej8rju&period=2017Q1")
        .to_return(status: 200, body: "")
    end
  end
end
