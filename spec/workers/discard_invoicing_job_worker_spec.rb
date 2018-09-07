

# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscardInvoicingJobWorker do
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, program: program }

  let(:worker) { DiscardInvoicingJobWorker.new }

  describe "DiscardInvoicingJobWorker" do
    it "mark as errored if no more queued and timedout" do
      job = project_anchor.invoicing_jobs.create(
        dhis2_period: "2016Q4",
        orgunit_ref:  "orgunit_ref",
        status:       "enqueued",
        created_at:   5.minutes.ago,
        updated_at:   5.minutes.ago
      )

      worker.perform

      job.reload
      expect(job.status).to eq("errored")
    end

    it "mark as errored if no more queued and timedout" do
      job = project_anchor.invoicing_jobs.create(
        dhis2_period: "2016Q4",
        orgunit_ref:  "orgunit_ref",
        status:       "enqueued"
      )

      worker.perform

      job.reload
      expect(job.status).to eq("enqueued")
    end
  end
end
