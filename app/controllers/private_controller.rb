class PrivateController < ApplicationController
  layout "layouts/private"
  helper_method :current_program

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  rescue_from ReadonlyProjectError, with: :not_editable

  def current_program
    current_user.program
  end

  def current_project(options = { raise_if_published: true })
    @current_project ||= current_project_anchor.projects.send(options[:project_scope] || :no_includes).find(params[:project_id]) if params[:project_id]
    unless @current_project.nil?
      raise ReadonlyProjectError, "No more editable project is published" if @current_project.published? && options[:raise_if_published]
    end
    @current_project
  end

  def current_project_anchor
    current_user.program.project_anchor
  end

  def not_editable
    flash[:failure] = "Sorry this project has been published you can't edit it anymore"
    redirect_to setup_project_path(params[:project_id])
  end
end
