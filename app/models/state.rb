# == Schema Information
#
# Table name: states
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  level      :string           default("activity"), not null
#  project_id :integer          not null
#  short_name :string
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

  validates :short_name, allow_blank: true, allow_nil: true, uniqueness: {
    scope:   :project_id,
    message: "Short name should be unique per project"
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

  def names(naming_patterns, activity)
    substitutions = substitutions_for(activity)
    Dhis2Name.new(
      long:  format(naming_patterns[:long], substitutions).strip,
      short: format(naming_patterns[:short], substitutions).strip,
      code:  format(naming_patterns[:code], substitutions).strip
    )
  end

  def substitutions_for(activity)
    {
      state_short_name:    short_name || name,
      raw_activity_code:   activity.code,
      activity_code:       activity.code.upcase,
      activity_name:       activity.name,
      activity_short_name: activity.short_name || activity.name,
      state_code:          code
    }
  end
end
