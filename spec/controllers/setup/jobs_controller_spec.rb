require "rails_helper"

RSpec.describe Setup::JobsController, type: :controller do
  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :index, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end

    describe "When authenticated #create" do
      include_context "basic_context"
      before(:each) do
        sign_in user
        Sidekiq::Testing.disable!
      end

      after(:each) do
        Sidekiq::Worker.clear_all
        Sidekiq::Testing.fake!
      end

      let(:dhis2_log_attributes) do
        {
          sent:   [
            {
              "value"       => "0.0", "period" => "201712",
              "comment"     => "$-pma_amount_patient_satisfaction_weighted-Total payment- PMA",
              "orgUnit"     => "sjudUrVxlBG",
              "dataElement" => "qmrBCjHt2UL"
            }
          ],
          status: {
            "status"            => "SUCCESS",
            "description"       => "Import process completed successfully",
            "import_count"      => {
              "deleted"  => 0,
              "ignored"  => 0,
              "updated"  => 433,
              "imported" => 0
            },
            "response_type"     => "ImportSummary",
            "data_set_complete" => "false"
          }
        }
      end

      it "display jobs" do
        full_project.project_anchor.dhis2_logs.create!(dhis2_log_attributes)

        InvoiceForProjectAnchorWorker.perform_async(full_project.project_anchor_id, 2016, 1, ["selected_org_unit_id"])
        get :index, params: { project_id: full_project.id }
        expect(assigns(:jobs).scheduled_jobs.first.period).to eq "2016Q1"
        expect(assigns(:jobs).last_jobs.first.period).to eq "201712"
      end
    end
  end
end
