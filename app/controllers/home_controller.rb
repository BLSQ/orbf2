class HomeController < PrivateController
  def index
    @current_program = current_program
    @current_program.create_project_anchor unless @current_program.project_anchor
    if @current_program.project_anchor.projects.empty?
      redirect_to setup_project_anchor_path
    else
      redirect_to setup_project_path(@current_program.project_anchor.latest_draft)
    end
  end
end
