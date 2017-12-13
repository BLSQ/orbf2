

class Dhis2SnapshotCompactor
  CLEANUP_INFOS = {
    "organisation_units" => %w[client coordinates access]
  }.freeze

  def compact!(snapshot)
    compacted = compact(snapshot)
    return unless compacted
    puts "saving id:#{snapshot.id} #{snapshot.kind} - #{snapshot.project_anchor.program.code} - #{snapshot.snapshoted_at}"
    snapshot.save!
  end

  def compact(snapshot)
    return false unless CLEANUP_INFOS[snapshot.kind]
    clean_count = 0
    snapshot.content.each do |row|
      CLEANUP_INFOS[snapshot.kind].each do |key_to_delete|
        clean_count += 1 if row["table"][key_to_delete]
        row["table"].delete(key_to_delete)
      end
    end
    if clean_count == 0
      puts "nothing to clean for id:#{snapshot.id} #{snapshot.kind} - #{snapshot.project_anchor.program.code} - #{snapshot.snapshoted_at}"
      return false
    end
  end
end
