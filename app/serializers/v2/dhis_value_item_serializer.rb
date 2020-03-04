# frozen_string_literal: true

class V2::DhisValueItemSerializer < V2::BaseSerializer
  attribute :value, &:display_name

  attribute :id
  attribute :name, &:display_name
  attribute :display_name
  attribute :kind, if: Proc.new { |record, params| record.respond_to?(:kind) && record&.kind.present? }
end
