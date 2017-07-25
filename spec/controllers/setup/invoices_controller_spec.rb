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

    it "calculate invoices" do
      stub_all_pyramid(full_project)
      stub_all_data_compound(full_project)
      stub_data_value_sets

      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:  org_unit_id,
          year:    "2017",
          quarter: "1"
        },
        simulate_draft: true
      }

      expect(response).to have_http_status(:success)
    end

    it "calculate invoices with mock_values" do
      stub_all_pyramid(full_project)
      stub_all_data_compound(full_project)

      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:      org_unit_id,
          year:        "2017",
          quarter:     "1",
          mock_values: "1"
        },
        simulate_draft: true
      }

      expect(response).to have_http_status(:success)
    end

    def stub_data_value_sets
      stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=true&endDate=2017-12-31&orgUnit=#{org_unit_id}&startDate=2017-01-01")
        .to_return(status: 200, body: "")
    end
  end
end
