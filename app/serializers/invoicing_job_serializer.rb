# frozen_string_literal: true

class InvoicingJobSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  attribute :org_unit,&:orgunit_ref
  attribute :dhis2_period
  attribute :user, &:user_ref
  attributes :processed_at, :errored_at, :duration_ms, :status, :last_error
  attribute :sidekiq_job_ref

end
