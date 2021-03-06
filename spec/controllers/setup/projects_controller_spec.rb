# frozen_string_literal: true

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

    let(:program) { create :program }

    let(:project) do
      project = full_project

      project.save!
      user.program = program
      user.save!
      user.reload

      project
    end

    DHIS2_URL = "https://sample.local"

    it "should allow project creation when valid infos is passed" do
      stub_dhis2_system_info_success(DHIS2_URL)

      post :create, params: {
        project: {
          name:       "project_name",
          dhis2_url:  DHIS2_URL,
          user:       "username",
          password:   "password",
          bypass_ssl: false
        }
      }
      expect(response).to redirect_to("/")
      expect(flash[:notice]).to eq "Great your dhis2 connection looks valid !"
      user.reload
      project = user.program.project_anchor.project
      expect(project.name).to eq("project_name")
      expect(project.engine_version).to eq(3)
    end

    it "check connection and save if ok on updates" do
      stub_dhis2_system_info_success(DHIS2_URL)
      post :update, params: {
        id:      project.id,
        project: {
          name:       "project_new name",
          dhis2_url:  DHIS2_URL,
          user:       "newusername",
          password:   "newpassword",
          bypass_ssl: false
        }
      }
      project.reload
      expect(project.name).to eq("project_new name")
    end
  end
end
