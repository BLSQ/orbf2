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

  attributes :name do |version, params|
    object = params[:hesabu_objects]["#{version.item_type}-#{version.item_id}"]
    [
      version.item_type, 
      object.try(:name) || object.try(:code) || object.try(:email), 
      "#{version.item_id}"
    ].select {|d| d}.join(" - ")
  end 

  attributes :path do |object, params|
    path = nil
    version = object
    object = params[:hesabu_objects]["#{version.item_type}-#{version.item_id}"]
    if object && version.item_type == "Formula"
      formula = object
      kind = FORMULA_TYPES[formula.rule.kind]
      path = {
        parentId: formula.rule.package_id ? formula.rule.package_id : formula.rule.payment_rule_id,
        parentKind:  formula.rule.package_id ? "sets": "compounds",
        kind: kind + "_formulas",
        itemId: object.id
      }
    end 

    if object && version.item_type == "Rule"
      rule = object
      kind = FORMULA_TYPES[rule.kind]
      path = {
        parentId: rule.package_id ? rule.package_id : rule.payment_rule_id,
        parentKind:  rule.package_id ? "sets": "compounds",
        kind: kind + "_formulas",
      }
    end     

    if object && version.item_type == "PackagePaymentRule"
      path = {
        parentId: object.payment_rule_id,
        parentKind:  "compounds",
      }
    end

    if object && version.item_type == "DecisionTable"
      decision_table = object
      path = {
        parentId: decision_table.rule.package_id ? decision_table.rule.package_id : decision_table.rule.payment_rule_id,
        parentKind:  decision_table.rule.package_id ? "sets": "compounds",
        kind: "topic/decisions",
        itemId: object.id
      }
    end

    if object && ["ActivityPackage", "PackageState"].include?(version.item_type)
      path = {
        parentId: object.package_id,
        parentKind: "sets",
        kind: "topic_formulas"
      }
    end

    if object && version.item_type == "PackageEntityGroup"
      path = {
        parentId: object.package_id,
        parentKind: "sets"  
      }
    end

    if object && version.item_type == "User"
      user = object
      path = {
        parentKind: "users",
      }
    end
    path
  end
end
