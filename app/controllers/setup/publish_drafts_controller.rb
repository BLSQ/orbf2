class Setup::PublishDraftsController < PrivateController
  def create
    new_project = current_project.publish(project_params[:publish_date])
    flash[:success] = "Project published successfuly"
    redirect_to setup_project_path(new_project.id)
  end

  private

  def project_params
    params.require(:project).permit(:publish_date)
  end
end
