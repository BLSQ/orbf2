require "rails_helper"

RSpec.describe Setup::SnapshotsController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      post :create, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #create" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:project) { full_project }
    let(:frozen_now) { Time.utc(2026, 5, 20, 10, 30, 0) }

    around(:each) do |example|
      travel_to(frozen_now) { example.run }
    end

    def expect_snapshot_enqueued_for(iso8601)
      expect(Dhis2SnapshotWorker).to have_enqueued_sidekiq_job(project.project_anchor.id, iso8601)
      expect(Dhis2SnapshotWorker.jobs.size).to eq(1), "expected a single snapshot job, got #{Dhis2SnapshotWorker.jobs.map { |j| j['args'] }}"
    end

    it "schedules a dhis2 snapshot for now when no date is given" do
      post :create, params: { project_id: project.id }

      expect_snapshot_enqueued_for("2026-05-20T10:30:00Z")
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Dhis2 snapshot scheduled... you will have fresh data in a few minutes")
    end

    it "schedules a dhis2 snapshot for the given date" do
      post :create, params: { project_id: project.id, now: "2024-03-15" }

      expect_snapshot_enqueued_for("2024-03-15T00:00:00Z")
    end

    it "falls back to now when the date can't be parsed" do
      post :create, params: { project_id: project.id, now: "not-a-date" }

      expect_snapshot_enqueued_for("2026-05-20T10:30:00Z")
    end

    it "falls back to now when the date is invalid" do
      post :create, params: { project_id: project.id, now: "2024-13-45" }

      expect_snapshot_enqueued_for("2026-05-20T10:30:00Z")
    end
  end
end
