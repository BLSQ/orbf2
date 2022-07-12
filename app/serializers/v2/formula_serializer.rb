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

  attributes :available_variables, if: EDITION_DETAILS do |object, record_serialization_params|
    object.rule.available_variables
  end

  attributes :exportable_ifs, if: EDITION_DETAILS do |object, record_serialization_params|
    object.available_exportable_formula_codes
  end

  attributes :mock_values, if: EDITION_DETAILS do |object, record_serialization_params|
    {}
  end

  has_many :formula_mappings, serializer: V2::FormulaMappingSerializer, record_type: :formulaMapping
end
