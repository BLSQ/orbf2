# frozen_string_literal: true

class V2::BaseSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower
end
