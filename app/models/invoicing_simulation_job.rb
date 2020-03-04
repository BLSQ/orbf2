# frozen_string_literal: true
# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :bigint(8)        not null, primary key
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

class InvoicingSimulationJob < InvoicingJob
  def self.scope_for(project_anchor)
    project_anchor.invoicing_simulation_jobs
  end

  def self.find_invoicing_job(project_anchor, period, orgunit_ref)
    scope_for(project_anchor).where(
      dhis2_period: period,
      orgunit_ref:  orgunit_ref
    ).first_or_create(
      dhis2_period: period,
      orgunit_ref:  orgunit_ref
    )
  end
end
