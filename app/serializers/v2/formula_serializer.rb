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
end
