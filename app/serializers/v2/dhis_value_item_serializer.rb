# frozen_string_literal: true

class V2::DhisValueItemSerializer < V2::BaseSerializer
  attribute :value do |item|
    # if item.type&.nil?
    #   item.id
    # else
      item.display_name
    # end
  end

  attribute :id
  attribute :name do |item|
    item.display_name
  end
end
