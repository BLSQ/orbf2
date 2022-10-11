# == Schema Information
#
# Table name: dhis2_snapshot_changes
#
#  id                :bigint(8)        not null, primary key
#  values_after      :jsonb
#  values_before     :jsonb
#  whodunnit         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dhis2_id          :string           not null
#  dhis2_snapshot_id :integer
#
# Indexes
#
#  index_dhis2_snapshot_changes_on_dhis2_snapshot_id  (dhis2_snapshot_id)
#

class Dhis2SnapshotChange < ApplicationRecord
  belongs_to :dhis2_snapshot, inverse_of: :dhis2_snapshot_changes

  def inspect_modifications
    log "*** #{dhis2_snapshot.snapshoted_at} #{dhis2_snapshot.kind[0..-2]} #{dhis2_id}"
    keys = (values_after.keys + values_before.keys).uniq
    keys.each do |k|
      if values_after[k].is_a? Array
        log_array(values_before[k], values_after[k])
      else
        log_default(values_before[k], values_after[k])
      end
    end
  end

  def log_array(before, after)
    log [
      "    added   #{(after - before)}",
      "    removed #{(before - after)}",
      " by #{whodunnit}"
    ].join("\n")
  end

  def log_default(before, after)
    log [
      "before #{before}",
      "after  #{after}",
      " by #{whodunnit}"
    ].join("\t")
  end

  def log(msg)
    puts msg
  end
end
