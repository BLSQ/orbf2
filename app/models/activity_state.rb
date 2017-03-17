# == Schema Information
#
# Table name: activity_states
#
#  id                 :integer          not null, primary key
#  external_reference :string
#  name               :string           not null
#  state_id           :integer          not null
#  activity_id        :integer          not null
#  stable_id          :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  kind               :string           default("data_element"), not null
#  formula            :string
#

class ActivityState < ApplicationRecord
  belongs_to :activity, inverse_of: :activity_states
  belongs_to :state

  validates :state_id, presence: { message: "Select a state or remove this activity from the list" }
  validates :external_reference, presence: true, if: :kind_data_element?
  validates :name, presence: true

  validates_uniqueness_of :state_id, scope: [:activity_id]

  def kind_data_element?
    kind == 'data_element'
  end

  def kind_formula?
    kind == 'formula'
  end

  def kind_indicator?
    kind == 'indicator'
  end

  def to_unified_h
    {
      stable_id:          stable_id,
      name:               name,
      external_reference: external_reference,
      state:              state_id
    }
  end

end
