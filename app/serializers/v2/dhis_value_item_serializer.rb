# frozen_string_literal: true

class V2::DhisValueItemSerializer < V2::BaseSerializer
  attribute :value do |rec| 
    rec.display_name
  end
  attribute :id
  attribute :name do |rec| 
    rec.display_name
  end
  attribute :display_name do |rec| 
    rec.display_name
  end
  attribute :kind, if: Proc.new { |record, params| record.respond_to?(:kind) && record&.kind.present? }
end
