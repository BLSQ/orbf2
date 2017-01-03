module RulesHelper
  def rule_name(rule)
    hierarchy = []
    hierarchy << rule.payment_rule.project.name if rule.payment_rule
    hierarchy << rule.package.project.name if rule.package
    hierarchy << rule.package.name if rule.package
    hierarchy << rule.kind

    hierarchy.join(" > ")
  end
end
