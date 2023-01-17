# frozen_string_literal: true

class V2::ActivitySerializer < V2::BaseSerializer
  set_type :topic

  attributes :code
  attributes :name
  attributes :short_name
  attributes :created_at
  attributes :updated_at
  attributes :stable_id

  has_many :input_mappings, serializer: ::V2::ActivityStateSerializer do |activity|
    activity.activity_states
  end

  has_many :formula_mappings do |activity|
  end
end
