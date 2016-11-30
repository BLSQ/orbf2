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

    it "should autocomplete org unit groups" do
      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?filter=name:ilike:term")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))

      get :organisation_unit_group, params: { project_id: project.id, term: "term" }
      expect(assigns(:items).first).to eq(value: "CHC", id: "CXw2yu5fodb")
    end
  end
end
