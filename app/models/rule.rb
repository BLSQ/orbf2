# == Schema Information
#
# Table name: rules
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  kind       :string           not null
#  package_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


class Rule < ApplicationRecord
  RULE_TYPES = %w(activity package).freeze
  belongs_to :package
  has_many :formulas

  accepts_nested_attributes_for :formulas, reject_if: :all_blank, allow_destroy: true

  validates :kind, presence: true, inclusion: { in: RULE_TYPES }
  validates :name, presence: true
  validate :formulas, :formulas_are_coherent

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = Rules::Solver.escapeString(name)
    facts
  end

  def formulas_are_coherent
    Rules::Solver.new.validate_formulas(self)
  end

  def fake_facts
    if kind == "activity"
      {
        claimed:   "1.0",
        verified:  "1.0",
        declared:  "1.0",
        validated: "1.0",
        tarif:     "100"
      }
    else
      {

      }
    end
  end
end
