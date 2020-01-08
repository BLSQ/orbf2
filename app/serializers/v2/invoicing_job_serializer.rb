# frozen_string_literal: true

class V2::InvoicingJobSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  attribute :org_unit, &:orgunit_ref
  attribute :org_unit_name
  attribute :dhis2_period
  attribute :user, &:user_ref
  attributes :created_at, :processed_at, :errored_at, :duration_ms, :status, :last_error
  attribute :sidekiq_job_ref

  attribute :is_alive, &:alive?
  attribute :result_url, &:result_url
end
