# frozen_string_literal: true
# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :integer          not null, primary key
#  dhis2_period      :string           not null
#  duration_ms       :integer
#  errored_at        :datetime
#  last_error        :string
#  orgunit_ref       :string           not null
#  processed_at      :datetime
#  sidekiq_job_ref   :string
#  status            :string           default("enqueued")
#  type              :string           default("InvoicingJob")
#  user_ref          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_anchor_id :integer          not null
#
# Indexes
#
#  index_invoicing_jobs_on_anchor_ou_period   (project_anchor_id,orgunit_ref,dhis2_period,type) UNIQUE
#  index_invoicing_jobs_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

require "rails_helper"

RSpec.describe InvoicingJob, type: :model do
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, program: program }

  describe "alive?" do
    it "is not alive if processed" do
      job = project_anchor.invoicing_jobs.build(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref", status: "processed")
      expect(job.alive?).to eq false
    end

    it "is not alive if processed and timedout" do
      job = project_anchor.invoicing_jobs.build(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref", status: "processed", updated_at: 5.days.ago)
      expect(job.alive?).to eq false
    end

    it "is not alive if errored" do
      job = project_anchor.invoicing_jobs.build(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref", status: "errored")
      expect(job.alive?).to eq false
    end

    it "is not alive not processed or errored but timedout" do
      job = project_anchor.invoicing_jobs.build(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref", status: "enqueued", updated_at: 5.days.ago)
      expect(job.alive?).to eq false
    end

    it "is alive if enqueued" do
      job = project_anchor.invoicing_jobs.create!(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref", status: "enqueued")
      expect(job.alive?).to eq true
    end

    it "new job is immediately alive" do
      job = project_anchor.invoicing_jobs.create!(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref")
      expect(job.alive?).to eq true
    end
  end

  it "handle nicely when no invoicing job" do
    InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
      sleep 0.5
    end
    expect(InvoicingJob.all.size).to eq(0)
  end

  describe "when invoicing job exist" do
    let!(:invoicing_job) { project_anchor.invoicing_jobs.create!(dhis2_period: "2016Q4", orgunit_ref: "orgunit_ref", status: "enqueued") }

    it "track duration on success and resets error infos" do
      slept = false
      InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
        sleep 0.5
        slept = true
      end
      invoicing_job.reload
      expect(slept).to eq true
      expect(invoicing_job.status).to eq("processed")
      expect(invoicing_job.duration_ms).to be >= 400

      expect(invoicing_job.processed_at).not_to be_nil
      expect(invoicing_job.errored_at).to be_nil
      expect(invoicing_job.last_error).to be_nil
    end

    it "track duration on error and resets processed info even " do
      invoicing_job
      slept = false
      expect {
        InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
          sleep 0.5
          slept = true
          raise "Failed miserably"
        end
      }.to raise_error("Failed miserably")
      invoicing_job.reload

      expect(invoicing_job.status).to eq("errored")
      expect(invoicing_job.processed_at).to be_nil
      expect(invoicing_job.errored_at).not_to be_nil
      expect(invoicing_job.last_error).to eq("RuntimeError: Failed miserably")
      expect(invoicing_job.duration_ms).to be >= 400
    end

    it "track duration on local return in blockand resets processed info" do
      invoicing_job
      slept = false
      action

      invoicing_job.reload

      expect(invoicing_job.status).to eq("processed")
      expect(invoicing_job.duration_ms).to be >= 400

      expect(invoicing_job.processed_at).not_to be_nil
      expect(invoicing_job.errored_at).to be_nil
      expect(invoicing_job.last_error).to be_nil
    end

    def action
      InvoicingJob.execute(project_anchor, "2016Q4", "orgunit_ref") do
        sleep 0.5
        slept = true
        return "456747"
      end
    end
  end

  describe "processed_after?" do
    it 'true for processed and after' do
      job = FactoryBot.build_stubbed(:invoicing_simulation_job, :processed)
      job.processed_at = 9.minutes.ago
      expect(job.processed_after?(time_stamp: 10.minutes.ago)).to eq true
    end

    it 'false for processed and before timestamp' do
      job = FactoryBot.build_stubbed(:invoicing_simulation_job, :processed)
      job.processed_at = 11.minutes.ago
      expect(job.processed_after?(time_stamp: 10.minutes.ago)).to eq false
    end

    it 'false for not processed' do
      job = FactoryBot.build_stubbed(:invoicing_simulation_job, :errored)
      job.processed_at = 11.minutes.ago
      expect(job.processed_after?(time_stamp: 10.minutes.ago)).to eq false
    end
  end

  describe "status" do
    it 'adds scopes' do
      processed_job = FactoryBot.create(:invoicing_simulation_job, :processed)
      errored_job = FactoryBot.create(:invoicing_simulation_job, :errored)
      new_job = FactoryBot.create(:invoicing_simulation_job)
      expect(InvoicingJob.processed.pluck(:id)).to eq([processed_job.id])
      expect(InvoicingJob.errored.pluck(:id)).to eq([errored_job.id])
      expect(InvoicingJob.enqueued.pluck(:id)).to eq([new_job.id])
    end

    it 'complains on invalid state' do
      new_job = FactoryBot.create(:invoicing_simulation_job)

      expect {
        new_job.status = "amazing-but-faulty"
      }.to raise_error(ArgumentError)
    end

    it 'defaults to enqueued' do
      new_job = FactoryBot.create(:invoicing_simulation_job)
      expect(new_job.enqueued?).to eq(true)
    end
  end
end
