class PrivateController < ApplicationController
  layout "layouts/private"

  protect_from_forgery with: :exception
  before_action :authenticate_user!
end
