class V2::BaseSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
end
