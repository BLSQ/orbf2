require "rails_helper"

RSpec.describe Setup::InvoicesController, type: :controller do
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

    it "displays the form for entities" do
      get :new, params: { project_id: full_project.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:invoicing_request)).not_to be nil
    end

    it "calculate invoices" do
      stub_orgunit
      stub_data_value_sets

      post :create, params: {
        project_id:        full_project.id,
        invoicing_request: {
          entity:  "CV4IXOSr5ky",
          year:    "2017",
          quarter: "1"
        }
      }

      expect(response).to have_http_status(:success)
    end

    def stub_orgunit
      stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnits/CV4IXOSr5ky")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnit.json"))
    end

    def stub_data_value_sets
      stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=true&endDate=2017-03-31&orgUnit=BV4IomHvri4&startDate=2017-01-01")
        .to_return(status: 200, body: "")
    end
  end
end
