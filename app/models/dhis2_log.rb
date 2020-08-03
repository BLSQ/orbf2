# == Schema Information
#
# Table name: dhis2_logs
#
#  id                :bigint(8)        not null, primary key
#  sent              :jsonb
#  sidekiq_job_ref   :string
#  status            :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  invoicing_job_id  :bigint(8)
#  project_anchor_id :integer
#
# Indexes
#
#  index_dhis2_logs_on_invoicing_job_id   (invoicing_job_id)
#  index_dhis2_logs_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (invoicing_job_id => invoicing_jobs.id)
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

class Dhis2Log < ApplicationRecord
  belongs_to :project_anchor

  belongs_to :invoicing_job, inverse_of: :dhis2_logs, optional: true

  def orgunit_ids
    sent.map { |data_value| data_value["orgUnit"] }.uniq
  end

  def periods
    sent.map { |data_value| data_value["period"] }.uniq.sort
  end
end
