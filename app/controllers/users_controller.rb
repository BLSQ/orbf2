class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_dev!

  def index
    @users = User.order(:id)
  end

  def impersonate
    user = User.find(params[:id])
    impersonate_user(user)
    redirect_to root_path
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to root_path
  end

  private

  def ensure_dev!
    Scorpio.is_developer?(current_user)
  end
end
