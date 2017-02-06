# == Schema Information
#
# Table name: activity_states
#
#  id                 :integer          not null, primary key
#  external_reference :string           not null
#  name               :string           not null
#  state_id           :integer          not null
#  activity_id        :integer          not null
#  stable_id          :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class ActivityState < ApplicationRecord
  belongs_to :activity, inverse_of: :activity_states
  belongs_to :state

  validates :state_id, presence: { message: "Select a state or remove this activity from the list" }
  validates :external_reference, presence: true
  validates :name, presence: true

  validates_uniqueness_of :state_id, scope: [:activity_id]

  def to_unified_h
    {
      stable_id:          stable_id,
      name:               name,
      external_reference: external_reference,
      state:              state_id
    }
  end
end
