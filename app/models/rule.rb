
class Rule
  include ActiveModel::Model
  RULE_TYPES = %w(activity package).freeze

  attr_accessor :name, :type, :formulas

  validates :frequency, presence: true, inclusion: { in: RULE_TYPES }
  validates :name, presence: true

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = "'#{name.tr("'", ' ')}'"
    facts
  end
end
