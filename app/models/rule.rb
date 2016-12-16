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
  has_many :formulas, dependent: :destroy, inverse_of: :rule

  accepts_nested_attributes_for :formulas, reject_if: :all_blank, allow_destroy: true

  validates :kind, presence: true, inclusion: {
    in:      RULE_TYPES,
    message: "%{value} is not a valid see #{RULE_TYPES.join(',')}"
  }
  validates :name, presence: true
  validates :formulas, length: { minimum: 1 }
  validate :formulas, :formulas_are_coherent

  def activity_kind?
    kind == "activity"
  end

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = Rules::Solver.escapeString(name)
    facts
  end

  def formulas_are_coherent
    Rules::Solver.new.validate_formulas(self) if name
  end

  def available_variables
    var_names = []
    if kind == "activity"
      var_names << package.states.map(&:name).map(&:underscore) if package
      var_names << "tarif"
      var_names << formulas.map(&:code)
    else
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }
    end
    var_names.flatten
  end

  def available_variables_for_values
    var_names = []
    if kind == "package" && package.activity_rule
      var_names << package.activity_rule.formulas.map(&:code).map { |code| "#{code}_values" }
    end
    var_names.flatten
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
