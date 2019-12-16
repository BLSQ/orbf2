class V2::OrgUnitSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :display_name
end
