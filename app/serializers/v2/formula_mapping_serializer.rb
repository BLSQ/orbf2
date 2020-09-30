# frozen_string_literal: true

class V2::FormulaMappingSerializer < V2::BaseSerializer
  class ExternalReference
    attr_accessor :id, :value, :display_name, :kind
    def initialize(id:, value:, display_name:, kind: nil)
      @id = id
      @value = value
      @display_name = display_name
      @kind = kind
    end
  end

  set_type :formula_mapping

  attributes :kind
  attributes :topic_id do |fm|
    fm.activity_id ? fm.activity_id.to_s : nil
  end
  attributes :external_reference do |fm|
    fm.external_reference
  end

  belongs_to :external_ref, serializer: V2::DhisValueItemSerializer do |mapping|
    ExternalReference.new(id: mapping.external_reference,
                          value: mapping.external_reference,
                          display_name: mapping.names.values[:long])
  end
end
