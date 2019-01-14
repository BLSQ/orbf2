# frozen_string_literal: true

# == Schema Information
#
# Table name: activity_states
#
#  id                 :integer          not null, primary key
#  external_reference :string
#  formula            :string
#  kind               :string           default("data_element"), not null
#  name               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_id        :integer          not null
#  stable_id          :uuid             not null
#  state_id           :integer          not null
#
# Indexes
#
#  index_activity_states_on_activity_id                         (activity_id)
#  index_activity_states_on_external_reference_and_activity_id  (external_reference,activity_id) UNIQUE
#  index_activity_states_on_state_id                            (state_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (state_id => states.id)
#

class ActivityState < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :activity
  delegate :program_id, to: :activity

  belongs_to :activity, inverse_of: :activity_states
  belongs_to :state

  validates :state, presence: { message: "Select a state or remove this activity from the list" }
  validates :external_reference, presence: true, if: :kind_data_element?
  validates :name, presence: true

  validates :state_id, uniqueness: { scope: [:activity_id] }

  KIND_DATA_ELEMENT = "data_element"
  KIND_INDICATOR = "indicator"
  KIND_DATA_ELEMENT_COC = "data_element_coc"
  KIND_FORMULA = "formula"

  KINDS = [
    KIND_DATA_ELEMENT,
    KIND_FORMULA,
    KIND_INDICATOR,
    KIND_DATA_ELEMENT_COC
  ].freeze

  validates :kind, inclusion: {
    in:      KINDS,
    message: "%{value} is not a valid see #{KINDS.join(',')}"
  }

  def external_reference=(external_reference)
    external_reference = nil if external_reference.blank?
    self[:external_reference] = external_reference
  end

  def kind_data_element?
    kind == KIND_DATA_ELEMENT
  end

  def kind_formula?
    kind == KIND_FORMULA
  end

  def kind_indicator?
    kind == KIND_INDICATOR
  end

  def kind_data_element_coc?
    kind == KIND_DATA_ELEMENT_COC
  end

  def data_element_related?
    kind_data_element? || kind_data_element_coc?
  end

  def data_element_id
    external_reference.split(".")[0]
  end

  def to_unified_h
    {
      stable_id:          stable_id,
      name:               name,
      external_reference: external_reference,
      state:              state.code
    }
  end
end
