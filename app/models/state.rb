# == Schema Information
#
# Table name: states
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  configurable :boolean          default(FALSE), not null
#  level        :string           default("activity"), not null
#  project_id   :integer          not null
#  short_name   :string
#

class State < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, format: {
    with:    Formula::REGEXP_VALIDATION,
    message: ": should only contains lowercase letters and _ like 'quality_score' or 'claimed' vs %{value}"
  }
  belongs_to :project, inverse_of: :states

  validates :name, uniqueness: {
    scope:   :project_id,
    message: "state name should be unique per project"
  }

  def self.configurables(conf = "")
    if conf == ""
      where("configurable= ? OR configurable= ?", true, false)
    else
      where configurable: conf
    end
  end

  def code
    @code ||= Codifier.codify(name)
  end

  def package_level?
    level == "package"
  end

  def activity_level?
    level == "activity"
  end

  def to_unified_h
    { name: name }
  end

  def name_for_mass_creation(naming_pattern, activity, state)
    state_short_name = state.short_name ||= state.name
    {
      short: format(naming_pattern[:short], activity_short_name: activity.short_name, state_short_name: state_short_name, activity_code: activity.code.humanize).strip,
      long:  format(naming_pattern[:long], state_short_name: state_short_name, activity_code: activity.code.humanize, activity_name: activity.name).strip
    }
  end
end
