class ProjectsController < PrivateController
  def create
    project = current_program.build_project(project_params)
    answer = project.verify_connection

    if answer[:status] == :ok
      current_program.project = project
      current_program.save!
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
