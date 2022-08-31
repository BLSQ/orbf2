# frozen_string_literal: true

class V2::UserSerializer < V2::BaseSerializer
  set_type :user

  attributes :dhis2_user_ref
  attributes :email
  attributes :current_sign_in_at
  attributes :last_sign_in_at
  attributes :created_at
  attributes :updated_at
end