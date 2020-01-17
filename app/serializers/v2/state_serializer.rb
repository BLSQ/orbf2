# frozen_string_literal: true

class V2::StateSerializer < V2::BaseSerializer
  set_type :input

  attributes :name
  attributes :short_name
end
