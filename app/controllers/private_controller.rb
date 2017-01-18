class PrivateController < ApplicationController
  layout "layouts/private"
  helper_method :current_program

  protect_from_forgery with: :exception
  before_action :authenticate_user!

  def current_program
    current_user.program
  end

  def current_project
    @current_project ||= current_project_anchor.project
  end

  def current_project_anchor
    current_user.program.project_anchor
  end
end
