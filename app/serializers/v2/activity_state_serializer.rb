# frozen_string_literal: true

class V2::ActivityStateSerializer < V2::BaseSerializer
  class ExternalReference
    attr_accessor :id, :value, :display_name, :kind
    def initialize(id:, value:, display_name:, kind:)
      @id = id
      @value = value
      @display_name = display_name
      @kind = kind
    end
  end

  set_type :input_mapping

  attributes :formula
  attributes :name
  attributes :origin
  attributes :stable_id
  attributes :kind
  attributes :external_reference

  belongs_to :external_ref, serializer: V2::DhisValueItemSerializer do |activity_state|
    ExternalReference.new(id: activity_state.external_reference,
                          value: activity_state.external_reference,
                          display_name: activity_state.name,
                          kind: activity_state.kind)
  end

  has_one :input, serializer: V2::StateSerializer do |activity_state|
    activity_state.state
  end
end
