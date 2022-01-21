require "rails_helper"

RSpec.describe Setup::SnapshotsController, type: :controller do
  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      post :create, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:project) { full_project }
    it "should allow to schedule dhis2 snapshots" do
      post :create, params: { project_id: project.id }
      expect(Dhis2SnapshotWorker).to have_enqueued_sidekiq_job(project.project_anchor.id)
    end
  end
end
