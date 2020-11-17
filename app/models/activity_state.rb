# frozen_string_literal: true
# == Schema Information
#
# Table name: activity_states
#
#  id                 :bigint(8)        not null, primary key
#  external_reference :string
#  formula            :string
#  kind               :string           default("data_element"), not null
#  name               :string           not null
#  origin             :string           default("dataValueSets")
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

class ActivityStateValidator
  def self.validate(activity_state)
    if activity_state.kind_data_element_coc? && activity_state.external_reference.presence
      if !activity_state.external_reference.include?(".")
        activity_state.errors[:external_reference] << "should contains a dot like DATAELEMENTID.COCID"
      end
    end
    if (activity_state.kind_indicator? || activity_state.kind_data_element?)  && activity_state.external_reference.presence
      if activity_state.external_reference.include?(".")
        activity_state.errors[:external_reference] << "should NOT contains a dot like DATAELEMENTID.COCID"
      end
    end
  end
end

class ActivityState < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :activity
  delegate :program_id, to: :activity

  belongs_to :activity, inverse_of: :activity_states
  belongs_to :state

  validates :state, presence: { message: "Select a state or remove this activity from the list" }
  validates :external_reference, presence: true, if: :dhis2_related?
  validates :name, presence: true

  validates :formula, presence: true, if: :kind_formula?

  validate do |activity_state|
    ActivityStateValidator.validate(activity_state)
  end

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

  ORIGIN_DATAVALUESETS = "dataValueSets"
  ORIGIN_ANALYTICS = "analytics"
  ORIGINS = [
    ORIGIN_DATAVALUESETS,
    ORIGIN_ANALYTICS
  ].freeze

  validates :origin, inclusion: {
    in:      ORIGINS,
    message: "%{value} is not a valid see #{ORIGINS.join(',')}"
  }

  def external_reference=(external_reference)
    external_reference = nil if external_reference.blank?
    self[:external_reference] = external_reference
  end

  def origin_data_value_sets?
    origin == ORIGIN_DATAVALUESETS
  end

  def origin_analytics?
    origin == ORIGIN_ANALYTICS
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

  def dhis2_related?
    data_element_related? || kind_indicator?
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
