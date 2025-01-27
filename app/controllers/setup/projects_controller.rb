class Setup::ProjectsController < PrivateController
  def create
    project_anchor = current_program.project_anchor || current_program.build_project_anchor
    unless current_program.project_anchor.projects.empty?
      raise "can't create a new one, need to update existing one"
    end

    project = current_program.project_anchor.projects.build(project_params.merge(engine_version: 3))
    answer = project.verify_connection

    if answer[:status] == :ok
      project.project_anchor.save!
      ProjectCocAocReferenceWorker.perform_async(project.id)
      flash[:notice] = "Great your dhis2 connection looks valid !"
    else
      flash[:alert] = "Sorry your dhis2 connection looks invalid ! #{answer[:message]}"
    end
    redirect_to(root_path)
  end

  def update
    project = current_project
    project.update(project_params)
    answer = project.verify_connection

    if answer[:status] == :ok
      project.save!
      flash[:notice] = "Great your dhis2 connection looks valid !"
    else
      flash[:alert] = "Sorry your dhis2 connection looks invalid ! #{answer[:message]}"
    end
    redirect_to(root_path)
  end

  private

  def project_params
    params.require(:project).permit(
      :name,
      :dhis2_url,
      :password,
      :user,
      :bypass_ssl,
      :cycle,
      :qualifier,
      :dhis2_logs_enabled,
      :enabled
    )
  end

  def current_project(options = { raise_if_published: true })
    @current_project ||= current_project_anchor.projects.find(params[:id]) if params[:id]
    unless @current_project.nil?
      if @current_project.published? && options[:raise_if_published]
        raise ReadonlyProjectError, "No more editable project is published"
      end
    end
    @current_project
  end
end
