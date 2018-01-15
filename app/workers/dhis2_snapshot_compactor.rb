

class Dhis2SnapshotCompactor
  CLEANUP_INFOS = {
    "organisation_units" => %w[client coordinates access attribute_values users data_sets user_group_accesses],
    "data_elements"      => %w[access client user user_group_accesses]
  }.freeze

  def compact!(snapshot)
    compacted = compact(snapshot)
    return unless compacted
    Rails.logger.info "saving id:#{snapshot.id} #{snapshot.kind} - #{snapshot.project_anchor.program.code} - #{snapshot.snapshoted_at}"
    snapshot.save!
  end

  def compact(snapshot)
    unless CLEANUP_INFOS[snapshot.kind]
      Rails.logger.info "not cleanup for #{snapshot.kind} id:#{snapshot.id}"
      return false
    end
    clean_count = 0
    snapshot.content.each do |row|
      CLEANUP_INFOS[snapshot.kind].each do |key_to_delete|
        clean_count += 1 if row["table"][key_to_delete]
        row["table"].delete(key_to_delete)
      end
    end
    if clean_count == 0
      Rails.logger.info "nothing to clean for id:#{snapshot.id} #{snapshot.kind} - #{snapshot.project_anchor.program.code} - #{snapshot.snapshoted_at}"
      return false
    end
    Rails.logger.info "cleaned #{clean_count}"
    true
  end
end
