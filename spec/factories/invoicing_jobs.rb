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

FactoryBot.define do
  factory :invoicing_job do
    dhis2_period { "2018Q1" }
    duration_ms { 6.seconds * 1000 }
    orgunit_ref { "aaa_123" }
    type { "InvoicingJob" }
    project_anchor
  end

  factory :invoicing_simulation_job, parent: :invoicing_job do
    type { "InvoicingSimulationJob" }
  end

  trait :processed do
    processed_at { 10.minutes.ago }
    status { InvoicingJob.statuses[:processed] }
  end

  trait :errored do
    processed_at { nil }
    errored_at { 10.minutes.ago }
    last_error { "This was the error" }
    status { InvoicingJob.statuses[:errored] }
  end

  trait :with_result do
    result {
      ActiveStorage::Blob.create_after_upload! io: File.open("spec/fixtures/scorpio/invoice_zero.json"), filename: "invoice_zero.json", content_type: "application/json"
    }
  end
end
