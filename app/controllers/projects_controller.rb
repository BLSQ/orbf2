class ProjectsController < PrivateController
  def create
    project = Project.new(project_params)
    answer = project.verify_connection

    if answer[:status] == :ok
      current_user.project = project
      current_user.save!
      flash[:notice] = "Great your dhis2 connection looks valid !"
    else
      flash[:alert] = "Sorry your dhis2 connection looks invalid ! #{answer[:message]}"
    end
    redirect_to(root_path)
  end

  private

  def project_params
    params.require(:project).permit(:name, :dhis2_url, :password, :user, :bypass_ssl)
  end
end
