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
    puts "*** #{dhis2_snapshot.snapshoted_at} #{dhis2_snapshot.kind[0..-2]} #{dhis2_id}"
    keys = (values_after.keys + values_before.keys).uniq
    keys.each do |k|
      if values_after[k].is_a? Array
        puts "    added   #{values_after[k] - values_before[k]}"
        puts "    removed #{values_before[k] - values_after[k]}"
        puts " by #{whodunnit}"
      end
    end
  end
end
