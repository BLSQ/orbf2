class Setup::SeedsController < PrivateController
  def index
    current_user.program.create_project_anchor unless current_user.program.project_anchor
    project_anchor = current_user.program.project_anchor
    project_factory = ProjectFactory.new
    suffix = Time.now.to_s[0..15] + " - "
    project = project_factory.build(
      dhis2_url:      params[:local] ? "http://127.0.0.1:8085/" : "https://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: project_anchor
    )
    project_factory.update_links(project, suffix)

    project_anchor.projects.destroy_all
    project_anchor.projects.push project

    project.save!
    current_user.save!
    SynchroniseDegDsWorker.new.perform(project_anchor.id)
    Dhis2SnapshotWorker.new.perform(project_anchor.id)
    flash[:notice] = " created package and rules for #{suffix} : #{project.packages.map(&:name).join(', ')}"
    redirect_to root_path
  end
end
