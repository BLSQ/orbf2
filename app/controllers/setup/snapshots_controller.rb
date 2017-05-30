class Setup::SnapshotsController < PrivateController
  def create
    Dhis2SnapshotWorker.perform_async(current_project.project_anchor.id)
    flash[:notice] = "Dhis2 snapshot scheduled... you should fresh data in a few minutes"
    redirect_to root_path
  end
end
