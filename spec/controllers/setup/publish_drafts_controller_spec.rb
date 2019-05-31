# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::PublishDraftsController, type: :controller do
  include WebmockDhis2Helpers

  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      post :create, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    it "publishes" do
      post :create, params: {
        project_id: full_project.id,
        project:    {
          publish_date: "15/01/2010"
        }
      }
      
      expect(response).to redirect_to("/setup/projects/#{full_project.id + 1}")
    end
  end
end
