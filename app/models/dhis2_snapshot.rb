# == Schema Information
#
# Table name: dhis2_snapshots
#
#  id                :integer          not null, primary key
#  kind              :string           not null
#  content           :jsonb            not null
#  project_anchor_id :integer
#  dhis2_version     :string           not null
#  year              :integer          not null
#  month             :integer          not null
#  job_id            :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Dhis2Snapshot < ApplicationRecord
  after_update :store_changes

  belongs_to :project_anchor

  KINDS = %i[data_elements
             data_element_groups
             organisation_unit_group_sets
             organisation_unit_groups
             organisation_units
             indicators].freeze

  def kind_organisation_units?
    kind.to_sym == :organisation_units
  end

  def kind_organisation_unit_groups?
    kind.to_sym == :organisation_unit_groups
  end

  def kind_organisation_unit_group_sets?
    kind.to_sym == :organisation_unit_group_sets
  end

  def kind_data_elements?
    kind.to_sym == :data_elements
  end

  def kind_data_element_groups?
    kind.to_sym == :data_element_groups
  end

  def kind_indicators?
    kind.to_sym == :indicators
  end

  def snapshoted_at
    Date.parse("#{year}-#{month}-01").end_of_month
  end

  def content_for_id(id)
    item = content.detect { |row| row["table"]["id"] == id }
    item ? item["table"] : nil
  end

  def store_changes
    return if changes.empty?
    current = changes["content"].last&.map { |r| r["table"] }
    previous = changes["content"].first.map { |r| r["table"] }

    added_or_modifieds = (current - previous).index_by { |e| e["id"] }
    removed_or_modifieds = (previous - current).index_by { |e| e["id"] }

    all_ids = (added_or_modifieds.keys + removed_or_modifieds.keys).uniq

    all_ids.each do |dhis2_id|
      added_or_modified = added_or_modifieds[dhis2_id]
      removed_or_modified = removed_or_modifieds[dhis2_id]
      if added_or_modified && removed_or_modified
        attribute_keys = (added_or_modified.keys + removed_or_modified.keys).uniq
        attribute_keys.each do |k|
          next unless added_or_modified[k] != removed_or_modified[k]
          puts "SNAPSHOT #{id} #{kind} #{year} #{month} : #{dhis2_id} modified : #{k} current : #{added_or_modified[k]} vs previous : #{removed_or_modified[k]}"
          if added_or_modified[k].is_a? Array
            puts "    added   #{added_or_modified[k] - removed_or_modified[k]}"
            puts "    removed #{removed_or_modified[k] - added_or_modified[k]}"
          end
        end
      elsif added_or_modified
        puts "only added_or_modified"
      elsif removed_or_modified
        puts "only removed_or_modified"
      end
    end
  end
end
