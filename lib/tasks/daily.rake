namespace :daily do
  desc "Schedult Dhis2SnapshotWorker for all project anchor"
  task dhis2_snapshot: :environment do
    ProjectAnchor.find_each do |anchor|
      Dhis2SnapshotWorker.perform_async(anchor.id)
    end
  end
end
