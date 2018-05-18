require "rails_helper"

RSpec.describe Setup::MetadatasController, type: :controller do
  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      get :index, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #create" do
    include_context "basic_context"
    include WebmockDhis2Helpers

    let(:program) { create :program }

    let(:project) do
      project = full_project

      project.save!
      user.program = program
      user.save!
      user.reload

      project
    end

    before(:each) do
      project
      sign_in user
    end

    it "shows dhis2 data elements" do
      stub_all_data_compound(project)
      get :index, params: { project_id: project.id }
    end
  end
end
