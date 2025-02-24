# frozen_string_literal: true

class V2::InvoicingJobSerializer < V2::BaseSerializer
  attribute :org_unit do |rec| rec.orgunit_ref end
  attribute :org_unit_name
  attribute :dhis2_period
  attribute :user do |rec| rec.user_ref end 
  attributes :created_at, :processed_at, :errored_at, :duration_ms, :status, :last_error
  attribute :sidekiq_job_ref

  attribute :is_alive do |rec| rec.alive? end
  attribute :result_url do |rec| rec.result_url end
end
