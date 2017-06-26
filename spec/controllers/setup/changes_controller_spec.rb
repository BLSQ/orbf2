require "rails_helper"

RSpec.describe Setup::ChangesController, type: :controller do
  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :index, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:program) { create :program }

    let(:project) do
      project = full_project
      project.save!
      user.save!
      user.program = program
      project
    end

    describe "#new" do
      it "should display a form for current project with a few default" do
        project.update_attributes(dhis2_url: "http://new.url.be")
        with_versioning do
          project.entity_group.update_attributes(name: "updategroup")
        end
        get :index, params: { project_id: project.id }
        versions = assigns(:versions)
        expect(versions).not_to be_empty
      end
    end
  end
end
