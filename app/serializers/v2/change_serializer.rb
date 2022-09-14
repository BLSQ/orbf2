# frozen_string_literal: true

class V2::ChangeSerializer < V2::BaseSerializer
  set_type :change

  FORMULA_TYPES = {
    "activity" => "topic",
    "zone" => "zone",
    "payment" => "compound",
    "zone_activity" => "zone_topic",
    "package" => "set",
    "multi-entities" => "children"
  }

  attributes :created_at
  attributes :whodunnit
  attributes :author
  attributes :item_type
  attributes :item_id
  attributes :event
  
  attributes :diffs do |object, record_serialization_params|
    object.diffs.map do |diff|
      { field: diff[0], before: diff[1].changes[0], after: diff[1].changes[1] }
    end
  end

  attributes :path do |object, record_serialization_params|
    version = object
    object = instance_eval(version.item_type).find_by_id(version.item_id)
    if object && version.item_type == "Formula"
      formula = object
      kind = FORMULA_TYPES[formula.rule.kind]
      path = {
        parentId: formula.rule.package_id ? formula.rule.package_id : formula.rule.payment_rule_id,
        parentKind:  formula.rule.package_id ? "sets": "compounds",
        kind: kind + "_formulas",
        formulaId: object.id
      }
      path
    end 
  end
end
