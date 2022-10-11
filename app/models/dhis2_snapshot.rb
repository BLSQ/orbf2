# frozen_string_literal: true
# == Schema Information
#
# Table name: dhis2_snapshots
#
#  id                :integer          not null, primary key
#  content           :jsonb            not null
#  dhis2_version     :string           not null
#  kind              :string           not null
#  month             :integer          not null
#  year              :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  job_id            :string           not null
#  project_anchor_id :integer
#
# Indexes
#
#  index_dhis2_snapshots_on_project_anchor_id  (project_anchor_id)
#

class Dhis2Snapshot < ApplicationRecord
  after_update :store_changes

  belongs_to :project_anchor

  KINDS = %i[data_elements
             data_element_groups
             organisation_unit_group_sets
             organisation_unit_groups
             organisation_units
             indicators
             category_combos].freeze

  has_many :dhis2_snapshot_changes, dependent: :destroy

  # Generated with:
  #
  #       Dhis2Snapshot::KINDS.each do |kind|
  #         puts "scope :#{kind.to_sym}, -> { where(kind: '#{kind}')}"
  #       end
  scope :data_elements, -> { where(kind: 'data_elements')}
  scope :data_element_groups, -> { where(kind: 'data_element_groups')}
  scope :organisation_unit_group_sets, -> { where(kind: 'organisation_unit_group_sets')}
  scope :organisation_unit_groups, -> { where(kind: 'organisation_unit_groups')}
  scope :organisation_units, -> { where(kind: 'organisation_units')}
  scope :indicators, -> { where(kind: 'indicators')}
  scope :category_combos, -> { where(kind: 'category_combos')}

  # If any of the elements inside content match this dhis2_id, the
  # snapshot will be a match.
  scope :containing_dhis2_id, ->(id) {
    part_to_contain = [{ table: { id: id } }].to_json
    where("content @> ?", part_to_contain)
  }

  # If any of the elements inside content match this display name, the
  # snapshot will be a match.
  scope :containing_dhis2_display_name, ->(name) {
    part_to_contain = [{ table: { display_name: name } }].to_json
    where("content @> ?", part_to_contain)
  }

  attr_accessor :disable_tracking

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

  def kind_category_combos?
    kind.to_sym == :category_combos
  end

  def snapshoted_at
    Date.parse("#{year}-#{month}-01").end_of_month
  end

  def content_for_id(id)
    item = content.detect { |row| row["table"]["id"] == id }
    item ? item["table"] : nil
  end

  def append_content(line)
    content << { "table"=> line }
  end

  def save_mutation!(whodunnit)
    @whodunnit = whodunnit
    save!
  end

  def store_changes
    return if saved_changes.empty? || @disable_tracking

    current = saved_changes["content"].last&.map { |r| r["table"] }
    previous = saved_changes["content"].first.map { |r| r["table"] }

    Groups::TrackChanges.new(
      dhis2_snapshot: self,
      current:        current,
      previous:       previous,
      whodunnit:      @whodunnit
    ).call
  end
end
