# == Schema Information
#
# Table name: dhis2_logs
#
#  id                :integer          not null, primary key
#  sent              :jsonb
#  status            :jsonb
#  project_anchor_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Dhis2Log < ApplicationRecord
  belongs_to :project_anchor
end
