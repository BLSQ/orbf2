class Setup::SnapshotsController < PrivateController
  def create
    Dhis2SnapshotWorker.perform_async(current_project.project_anchor.id)
    flash[:notice] = "Dhis2 snapshot scheduled... you will have fresh data in a few minutes"
    redirect_back(fallback_location: root_path)
  end
end
