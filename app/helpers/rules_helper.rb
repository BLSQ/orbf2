module RulesHelper
  def rule_name(rule)
    hierarchy = []
    hierarchy << rule.project.name if rule.project
    hierarchy << rule.package.project.name if rule.package
    hierarchy << rule.package.name if rule.package
    hierarchy << rule.kind

    hierarchy.join(" > ")
  end
end
