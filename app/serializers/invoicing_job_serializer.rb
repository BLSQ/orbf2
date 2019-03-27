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
#  status            :string
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
