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

  accepts_nested_attributes_for :activity_states, allow_destroy: true

  validates :name, presence: true
  validates :activity_states, length: { minimum: 1 }

  def activity_state(state)
    activity_state = activity_states.find { |as| as.state.id == state.id }
    puts "activity_state #{state.name} #{state.id} #{activity_state.name} #{activity_state.external_reference}" if activity_state
    activity_state
  end

  def to_unified_h
    {
      name:            name,
      stable_id:       stable_id,
      activity_states: Hash[

      ]
    }
  end
end
