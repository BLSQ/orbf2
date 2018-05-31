# == Schema Information
#
# Table name: formula_mappings
#
#  id                 :integer          not null, primary key
#  formula_id         :integer          not null
#  activity_id        :integer
#  external_reference :string           not null
#  kind               :string           not null
#

class FormulaMapping < ApplicationRecord
  include PaperTrailed

  delegate :project_id, to: :formula
  delegate :program_id, to: :formula

  validates :kind, presence: true, inclusion: {
    in:      Rule::RULE_TYPES,
    message: "%{value} is not a valid see #{Rule::RULE_TYPES.join(',')}"
  }

  validates :external_reference, presence: true
  belongs_to :formula, inverse_of: :formula_mappings
  belongs_to :activity

  def names
    if activity
      naming_patterns = activity.project.naming_patterns
      activity_short_name = activity.short_name || activity.name
      substitutions = {
        state_short_name:    formula.code.humanize,
        raw_activity_code:   activity.code,
        activity_code:       activity.code.humanize,
        activity_name:       activity.name,
        activity_short_name: activity_short_name,
        state_code:          formula.code
      }
      {
        long:  format(naming_patterns[:long], substitutions).strip,
        short: format(naming_patterns[:short], substitutions).strip,
        code:  format(naming_patterns[:code], substitutions).strip
      }
    else
      name = formula.code.humanize.strip
      {
        long:  name,
        short: name,
        code:  name
      }
    end
  end
end
