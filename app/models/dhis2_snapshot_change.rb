# == Schema Information
#
# Table name: dhis2_snapshot_changes
#
#  id                :integer          not null, primary key
#  dhis2_id          :string           not null
#  dhis2_snapshot_id :integer
#  values_before     :jsonb
#  values_after      :jsonb
#  whodunnit         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Dhis2SnapshotChange < ApplicationRecord
  belongs_to :dhis2_snapshot, inverse_of: :dhis2_snapshot_changes

  def inspect_modifications
    log "*** #{dhis2_snapshot.snapshoted_at} #{dhis2_snapshot.kind[0..-2]} #{dhis2_id}"
    keys = (values_after.keys + values_before.keys).uniq
    keys.each do |k|
      next unless values_after[k].is_a? Array
      log "    added   #{values_after[k] - values_before[k]}"
      log "    removed #{values_before[k] - values_after[k]}"
      log " by #{whodunnit}"
    end
  end

  def log(msg)
    puts msg
  end
end
