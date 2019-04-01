FactoryBot.define do
  factory :invoicing_job do
    dhis2_period { "2018Q1" }
    duration_ms { 6.seconds * 1000 }
    orgunit_ref { "aaa_123" }
    type { "InvoicingJob" }
  end

  factory :invoicing_simulation_job, parent: :invoicing_job do
    type { "InvoicingSimulationJob" }
  end

  trait :processed do
    processed_at { 10.minutes.ago }
    status { "processed" }
  end

  trait :errored do
    processed_at { nil }
    errored_at { 10.minutes.ago }
    last_error { "This was the error" }
    status { "errored" }
  end

  trait :with_result do
    result {
      ActiveStorage::Blob.create_after_upload! io: File.open("spec/fixtures/scorpio/invoice_zero.json"), filename: "invoice_zero.json", content_type: "application/json"
    }
  end
end
