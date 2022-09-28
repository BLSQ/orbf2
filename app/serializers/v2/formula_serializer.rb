# frozen_string_literal: true

class V2::FormulaSerializer < V2::BaseSerializer
  set_type :formula

  attributes :id
  attributes :code
  attributes :description
  attributes :exportable_formula_code
  attributes :expression
  attributes :frequency
  attributes :short_name
  attributes :created_at
  attributes :updated_at

  EDITION_DETAILS = proc { |_record, params| (params || {}).fetch(:with_edition_details, false) }

  KIND_TRANSLATION = {
    Rule::RULE_TYPE_ACTIVITY => "topic_formulas",
    Rule::RULE_TYPE_MULTI_ENTITIES => "children_formulas",
    Rule::RULE_TYPE_PACKAGE => "set_formulas",
    Rule::RULE_TYPE_ZONE => "zone_formulas",
    Rule::RULE_TYPE_ZONE_ACTIVITY => "zone_topic_formulas",
    Rule::RULE_TYPE_PAYMENT => "compound_formulas",
  }

  attributes :available_variables, if: EDITION_DETAILS do |object, record_serialization_params|
    object.rule.available_variables
  end

  attributes :exportable_ifs, if: EDITION_DETAILS do |object, record_serialization_params|
    object.available_exportable_formula_codes
  end

  attributes :mock_values, if: EDITION_DETAILS do |object, record_serialization_params|
    {}
  end

  attributes :parent_id, if: EDITION_DETAILS do |object, record_serialization_params|
    object.rule.parent_id
  end

  attributes :errors, if: EDITION_DETAILS do |object, record_serialization_params|
    object.rule.valid?
    object.rule.errors
  end

  attributes :kind, if: EDITION_DETAILS do |object, record_serialization_params|
    KIND_TRANSLATION[object.rule.kind]
  end

  attributes :parent_kind, if: EDITION_DETAILS do |object, record_serialization_params|
    object.rule.kind == Rule::RULE_TYPE_PAYMENT ? "compounds" : "sets"
  end

  attributes :parent_name, if: EDITION_DETAILS do |object, record_serialization_params|
    object.rule.package ? object.rule.package.name : object.rule.name
  end

  has_many :formula_mappings, serializer: V2::FormulaMappingSerializer, record_type: :formulaMapping

  has_many :used_formulas, serializer: V2::FormulaSerializer, record_type: :formula, if: EDITION_DETAILS do |object, record_serialization_params|
    object.used_formulas
  end

  has_many :used_by_formulas, serializer: V2::FormulaSerializer, record_type: :formula, if: EDITION_DETAILS do |object, record_serialization_params|
    object.used_by_formulas
  end
end
