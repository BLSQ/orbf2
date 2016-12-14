
class Rule
  include ActiveModel::Model
  attr_accessor :name, :type, :formulas

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = "'#{name.tr("'", ' ')}'"
    facts
  end
end
