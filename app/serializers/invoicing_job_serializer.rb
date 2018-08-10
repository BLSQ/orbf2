# frozen_string_literal: true

class InvoicingJobSerializer
  include FastJsonapi::ObjectSerializer
  attributes :orgunit_ref, :dhis2_period, :user_ref,
             :processed_at, :errored_at, :duration_ms,
             :status, :sidekiq_job_ref
end
