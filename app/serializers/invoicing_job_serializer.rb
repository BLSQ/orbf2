# frozen_string_literal: true

# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :integer          not null, primary key
#  project_anchor_id :integer          not null
#  orgunit_ref       :string           not null
#  dhis2_period      :string           not null
#  user_ref          :string
#  processed_at      :datetime
#  errored_at        :datetime
#  last_error        :string
#  duration_ms       :integer
#  status            :string
#  sidekiq_job_ref   :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class InvoicingJobSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  attribute :org_unit, &:orgunit_ref
  attribute :dhis2_period
  attribute :user, &:user_ref
  attributes :created_at, :processed_at, :errored_at, :duration_ms, :status, :last_error
  attribute :sidekiq_job_ref

  attribute :is_alive, &:alive?
end
