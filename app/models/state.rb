# == Schema Information
#
# Table name: states
#
#  id         :bigint(8)        not null, primary key
#  name       :string           not null
#  short_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#
# Indexes
#
#  index_states_on_project_id           (project_id)
#  index_states_on_project_id_and_name  (project_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

class State < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

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

  def code
    @code ||= Codifier.codify(name)
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
