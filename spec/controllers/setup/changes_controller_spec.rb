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
        with_versioning do
          project
          project.update(dhis2_url: "http://new.url.be")
          project.entity_group.update(name: "updategroup")
        end
        get :index, params: { project_id: project.id }
        versions = assigns(:versions)
        expect(versions).not_to be_empty
        project_version = PaperTrail::Version.where(item_type: "Project", item_id: project.id, event: "update").last
        expect(project_version).to be_present, "the project update should be versioned as Project-#{project.id}"
        expect(project_version.project_id).to eq(project.id)
        expect(project_version.program_id).to eq(project.program_id)
      end
    end
  end
end
