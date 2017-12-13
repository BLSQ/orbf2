namespace :snapshots do
  desc "compact"
  task compact: :environment do
    Dhis2Snapshot.find_each do |snapshot|
      Dhis2SnapshotCompactor.new.compact!(snapshot)
    end
  end
end
