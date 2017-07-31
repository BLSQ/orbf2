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
#  code       :string
#

class Activity < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

  belongs_to :project, inverse_of: :activities
  has_many :activity_states, dependent: :destroy
  has_many :activity_packages, dependent: :destroy

  accepts_nested_attributes_for :activity_states, allow_destroy: true

  validates :name, presence: true
  validates :activity_states, length: { minimum: 1 }
  validates :code, allow_blank: true, format: {
    with:    Formula::REGEXP_VALIDATION,
    message: ": should only contains lowercase letters and _ like 'assisted_deliveries' or 'vaccination_under_one_year' vs %{value}"
  }
  validates :code, uniqueness: { scope: :project_id }, allow_blank: true

  def activity_state(state)
    activity_states.find { |as| as.state.id == state.id }
  end

  def to_unified_h
    {
      name:            name,
      stable_id:       stable_id,
      activity_states: activity_states.map { |as| [as.stable_id, :to_unified_h] }.to_h
    }
  end
end
