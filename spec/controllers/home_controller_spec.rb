# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :controller do
  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      get :index, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:project) { full_project }

    it "redirects to setup projects when no project" do
      get :index
      expect(response).to redirect_to("/setup/projects")
    end

    it "redirect to lastest draft" do
      project.project_anchor = user.program.project_anchor
      project.save!
      get :index
      expect(response).to redirect_to("/setup/projects/#{project.id}")
    end
  end
end
