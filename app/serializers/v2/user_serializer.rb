# frozen_string_literal: true

class V2::UserSerializer < V2::BaseSerializer
  set_type :user

  attributes :dhis2_user_ref
  attributes :email
end