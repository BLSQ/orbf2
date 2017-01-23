class Setup::ProjectsController < PrivateController
  def create
    project_anchor = current_program.project_anchor || current_program.build_project_anchor
    project = current_program.project_anchor.projects.build(project_params)
    answer = project.verify_connection

    if answer[:status] == :ok
      project.project_anchor.save!
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
