namespace :snapshots do
  def dump_snapshot_sizes
    puts Dhis2Snapshot.all.select("id, kind, length(content::text) as contentlength").sort_by(&:contentlength).map(&:attributes)
  end

  desc "compact"
  task compact: :environment do
    dump_snapshot_sizes
    Dhis2Snapshot.all.find_each(batch_size: 1) do |snapshot|
      Dhis2SnapshotCompactor.new.compact!(snapshot)
    end
    dump_snapshot_sizes
  end
end
