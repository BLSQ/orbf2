# frozen_string_literal: true

class V2::ChangeSerializer < V2::BaseSerializer
  set_type :change

  attributes :created_at
  attributes :whodunnit
  attributes :author
  attributes :item_type
  attributes :item_id
  attributes :event
  attributes :diffs do |object, record_serialization_params|
    object.diffs.map do |diff|
      # byebug
      { diff: diff, html: diff[1].diff.format_as(:html) }
    end
  end
end
