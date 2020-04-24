# == Schema Information
#
# Table name: formula_mappings
#
#  id                 :bigint(8)        not null, primary key
#  external_reference :string           not null
#  kind               :string           not null
#  activity_id        :integer
#  formula_id         :integer          not null
#
# Indexes
#
#  index_formula_mappings_on_activity_id  (activity_id)
#  index_formula_mappings_on_formula_id   (formula_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (formula_id => formulas.id)
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
  belongs_to :activity, optional: true

  def project
    formula.rule.project
  end

  def names
    if activity
      naming_patterns = project.naming_patterns
      substitutions = substitutions_for(activity)
    else
      naming_patterns = project.naming_patterns_without_activity
      substitutions = substitutions_for_others
    end
    dhis2_name = {
      long:  format(naming_patterns[:long], substitutions).strip,
      short: format(naming_patterns[:short], substitutions).strip,
      code:  format(naming_patterns[:code], substitutions).strip
    }
    Dhis2Name.new(dhis2_name)
  end

  def data_element_ext_ref
    external_reference.split(".").first
  end

  def coc_ext_ref
    return nil unless has_coc_in_reference?

    external_reference.split(".").last
  end

  def has_coc_in_reference?
    external_reference.split(".").size > 1
  end

  def substitutions_for_others
    {
      state_short_name: formula.code.humanize,
      state_code:       formula.code
    }
  end

  def substitutions_for(activity)
    {
      state_short_name:    formula.short_name.presence || formula.code.humanize,
      raw_activity_code:   activity.code,
      activity_code:       activity.code.upcase,
      activity_name:       activity.name,
      activity_short_name: activity.short_name.presence || activity.name,
      state_code:          formula.code
    }
  end
end
