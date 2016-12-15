
class Rule
  include ActiveModel::Model
  RULE_TYPES = %w(activity package).freeze

  attr_accessor :name, :type, :formulas

  validates :type, presence: true, inclusion: { in: RULE_TYPES }
  validates :name, presence: true

  validate :formulas, :formulas_are_coherent

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = Rules::Solver.escapeString(self.name)
    facts
  end

  def formulas_are_coherent
    Rules::Solver.new.validate_formulas(self)
  end

  def fake_facts
    if type == "activity"
      {
        claimed: "1.0",
        verified: "1.0",
        declared: "1.0",
        validated: "1.0",
        tarif: "100"
      }
    else
      {

      }
    end
  end

end
