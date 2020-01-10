# frozen_string_literal: true

class V2::StateSerializer
  include FastJsonapi::ObjectSerializer
  set_type :input

  attributes :name
  attributes :short_name
end
