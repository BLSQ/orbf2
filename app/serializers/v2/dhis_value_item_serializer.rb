# frozen_string_literal: true

class V2::DhisValueItemSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :value do |item|
    if item.type.nil?
      item.id
    else
      item.display_name
    end
  end

  attribute :id
  attribute :name do |item|
    item.display_name
  end
end
