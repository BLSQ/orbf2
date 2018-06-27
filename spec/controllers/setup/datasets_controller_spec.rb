require "rails_helper"
require_relative "../../workers/dhis2_snapshot_fixture"
RSpec.describe Setup::DatasetsController, type: :controller do
  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :index, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    include Dhis2SnapshotFixture
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:program) { create :program }

    let(:project) do
      project = full_project
      project.entity_group.update!(external_reference: "GGghZsfu7qV")
      project.save!
      user.save!
      user.program = program
      project
    end

    let(:payment_rule) do
      project.payment_rules.first
    end

    it "should render list of datasets" do
      stub_snapshots(project)
      get :index, params: { project_id: project.id }
    end

    it "schedule create in a worker" do
      post :create, params: {
        project_id:        project.id,
        payment_rule_code: payment_rule.code,
        frequency:         "quarterly"
      }
      expect(OutputDatasetWorker).to have_enqueued_sidekiq_job(
        project.id,
        "payment_rule_pma",
        "quarterly",
        "modes"=>["create"]
      )
    end

    it "schedule update in a worker" do
      dataset = payment_rule.datasets.create!(frequency: "quarterly", external_reference: "fakedsid")

      put :update, params: {
        project_id: project.id,
        id:         dataset.id,
        dataset:    { sync_methods: OutputDatasetWorker::MODES }
      }
      expect(OutputDatasetWorker).to have_enqueued_sidekiq_job(
        project.id,
        "payment_rule_pma",
        "quarterly",
        "modes"=>%w[add_missing_de add_missing_ou remove_extra_de remove_extra_ou]
      )
    end
  end
end
