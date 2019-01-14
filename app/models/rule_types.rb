# frozen_string_literal: true

module RuleTypes
  class UnsupportedKind < StandardError; end

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

  RULE_TYPES_MAPPING ={
      RULE_TYPE_ACTIVITY => RuleTypes::ActivityRuleType,
      RULE_TYPE_PACKAGE => RuleTypes::PackageRuleType,
      RULE_TYPE_PAYMENT => RuleTypes::PaymentRuleType,
      RULE_TYPE_MULTI_ENTITIES => RuleTypes::MultiEntityRuleType,
      RULE_TYPE_ZONE => RuleTypes::ZoneRuleType,
      RULE_TYPE_ZONE_ACTIVITY => RuleTypes::ZoneActivityRuleType
    }.freeze

  def self.from_rule(rule)
    klazz = RULE_TYPES_MAPPING.fetch(rule.kind) do
      raise UnsupportedKind, "unsupported kind '#{rule.kind}' see #{RULE_TYPES}"
    end
    klazz.new(rule)
  end
end
