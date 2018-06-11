require "rails_helper"

RSpec.describe Setup::MetadatasController, type: :controller do
  describe "When non authenticated " do
    it "should redirect to sign on" do
      get :index, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated " do
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

    it "shows dhis2 data elements in edit mode" do
      stub_all_data_compound(project)
      get :index, params: { project_id: project.id, edit: true }
    end

    it "schedule worker to update" do
      stub_all_data_compound(project)
      put :update, params: {
        project_id: project.id,
        id:         "dhis2_my_id",
        name:       "long long new_name",
        short_name: "newshort_name",
        code:       "mycode"
      }
      expect(UpdateMetadataWorker).to have_enqueued_sidekiq_job(
        project.id,
        "dhis2_id"   => "dhis2_my_id",
        "name"       => "long long new_name",
        "short_name" => "newshort_name",
        "code"       => "mycode"
      )
    end
  end
end
