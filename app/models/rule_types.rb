# frozen_string_literal: true

module RuleTypes
  RULE_TYPE_MULTI_ENTITIES = "multi-entities"
  RULE_TYPE_ACTIVITY = "activity"
  RULE_TYPE_PACKAGE = "package"
  RULE_TYPE_PAYMENT = "payment"
  RULE_TYPE_ZONE = "zone"
  RULE_TYPE_ZONE_ACTIVITY = "zone_activity"

  RULE_TYPES = [
    RULE_TYPE_PAYMENT, RULE_TYPE_ACTIVITY,
    RULE_TYPE_PACKAGE, RULE_TYPE_MULTI_ENTITIES,
    RULE_TYPE_ZONE, RULE_TYPE_ZONE_ACTIVITY
  ].freeze

  def self.from_rule(rule)
    case rule.kind
    when RULE_TYPE_ACTIVITY
      RuleTypes::ActivityRuleType.new(rule)
    when RULE_TYPE_PACKAGE
      RuleTypes::PackageRuleType.new(rule)
    when RULE_TYPE_PAYMENT
      RuleTypes::PaymentRuleType.new(rule)
    when RULE_TYPE_MULTI_ENTITIES
      RuleTypes::MultiEntityRuleType.new(rule)
    when RULE_TYPE_ZONE
      RuleTypes::ZoneRuleType.new(rule)
    when RULE_TYPE_ZONE_ACTIVITY
      RuleTypes::ZoneActivityRuleType.new(rule)
    else
      raise "unsupported kind '#{rule.kind}' see #{RULE_TYPES}"
    end
  end
end
