# frozen_string_literal: true

class V2::RuleSerializer < V2::BaseSerializer
  set_type :rule

  attributes :name
  attributes :id
end
