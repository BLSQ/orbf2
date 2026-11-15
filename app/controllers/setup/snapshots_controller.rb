class Setup::SnapshotsController < PrivateController
  def create
    now = parse_now(params[:now])
    # sidekiq only accepts json args: pass the date as an iso8601 string, positional
    Dhis2SnapshotWorker.perform_async(current_project.project_anchor.id, now.iso8601)
    flash[:notice] = "Dhis2 snapshot scheduled... you will have fresh data in a few minutes"
    redirect_back(fallback_location: root_path)
  end

  private

  def parse_now(value)
    return Time.now.utc if value.blank?

    Time.zone.parse(value) || Time.now.utc
  rescue ArgumentError
    Time.now.utc
  end
end
