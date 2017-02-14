require "rails_helper"

RSpec.describe Setup::ProjectsController, type: :controller do
  describe "When non authenticated #index" do
    it "should redirect to sign on" do
      post :create
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    before(:each) do
      user.program = program
      user.save!
      sign_in user
    end

    DHIS2_URL = "https://sample.local".freeze

    it "should allow project creation when valid infos is passed" do
      stub_dhis2_system_info_success(DHIS2_URL)

      post :create, params: { project: {
        name: "project_name",
        dhis2_url: DHIS2_URL,
        user: "username",
        password: "password", bypass_ssl: false
      } }
      expect(response).to redirect_to("/")
      expect(flash[:notice]).to eq "Great your dhis2 connection looks valid !"
      user.reload
      expect(user.program.project_anchor.project.name).to eq("project_name")
    end
  end
end
