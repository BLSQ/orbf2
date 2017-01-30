# == Schema Information
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  project_id :integer          not null
#  stable_id  :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Activity < ApplicationRecord
  belongs_to :project, inverse_of: :activities
  has_many :activity_states, dependent: :destroy
  has_many :activity_packages, dependent: :destroy
end
