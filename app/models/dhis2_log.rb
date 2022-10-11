# == Schema Information
#
# Table name: dhis2_logs
#
#  id                :bigint(8)        not null, primary key
#  sent              :jsonb
#  status            :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_anchor_id :integer
#
# Indexes
#
#  index_dhis2_logs_on_project_anchor_id  (project_anchor_id)
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
