# == Schema Information
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  code       :string
#  name       :string           not null
#  short_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#  stable_id  :uuid             not null
#
# Indexes
#
#  index_activities_on_name_and_project_id  (name,project_id) UNIQUE
#  index_activities_on_project_id           (project_id)
#  index_activities_on_project_id_and_code  (project_id,code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

class Activity < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

  belongs_to :project, inverse_of: :activities
  has_many :activity_states, dependent: :destroy
  has_many :activity_packages, dependent: :destroy

  accepts_nested_attributes_for :activity_states, allow_destroy: true

  validates :name, presence: true
  validates :short_name, allow_blank: true, length: { minimum: 1, maximum: 40 }

  validates :code, allow_blank: true, format: {
    with:    Formula::REGEXP_VALIDATION,
    message: ": should only contains lowercase letters and _ like 'assisted_deliveries' or 'vaccination_under_one_year' vs %{value}"
  }
  validates :code, uniqueness: { scope: :project_id }, allow_blank: true

  before_validation :codify

  def codify
    self.code = Codifier.codify(name) if code.blank?
  end

  def code
    val = self[:code]
    if val.present?
      return val
    elsif name
      self[:code] = Codifier.codify(name)
      self[:code]
    end
  end

  def activity_state(state)
    activity_states.find { |as| as.state.id == state.id }
  end

  def missing_activity_states?
    activity_packages.any? do |activity_package|
      activity_package.package.missing_activity_states[self].any?
    end
  end

  def to_unified_h
    {
      name:            name,
      stable_id:       stable_id,
      activity_states: activity_states.map { |as| [as.stable_id, :to_unified_h] }.to_h
    }
  end
end
