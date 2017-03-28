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

class FormulaMapping  < ApplicationRecord
    validates :kind, presence: true, inclusion: {
      in:      Rule::RULE_TYPES,
      message: "%{value} is not a valid see #{Rule::RULE_TYPES.join(',')}"
    }

    validates :external_reference, presence: true
    belongs_to :formula, inverse_of: :formula_mappings
    belongs_to :activity


end
