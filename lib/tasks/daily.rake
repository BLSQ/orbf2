namespace :daily do
  desc "Schedule Dhis2SnapshotWorker for all project anchor"
  task dhis2_snapshot: :environment do
    ProjectAnchor.all.with_enabled_projects.find_each do |anchor|
      Dhis2SnapshotWorker.perform_async(anchor.id)
    end
  end
end
