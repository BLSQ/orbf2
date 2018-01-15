# == Schema Information
#
# Table name: project_anchors
#
#  id         :integer          not null, primary key
#  program_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProjectAnchor < ApplicationRecord
  belongs_to :program
  has_many :projects, inverse_of: :project_anchor, dependent: :destroy

  has_many :dhis2_snapshots, inverse_of: :project_anchor, dependent: :destroy
  has_many :dhis2_logs, inverse_of: :project_anchor, dependent: :destroy

  def invalid_project?
    project.nil? || project.invalid?
  end

  def project
    projects.first
  end

  def latest_draft
    projects.where(status: "draft").fully_loaded.last
  end

  def nearest_pyramid_for(date)
    kinds = %i[organisation_units organisation_unit_groups organisation_unit_group_sets]
    pyramid_snapshots = dhis2_snapshots.select("id, year, month, kind").where(kind: kinds)

    candidates = pyramid_snapshots.sort_by { |snap| [snap.kind, [snap.year, snap.month].join("-")] }

    final_candidates = kinds.map do |kind|
      kind_method = "kind_#{kind}?".to_sym
      [kind, nearest(candidates.select(&kind_method), date)]
    end.to_h

    final_snapshots = final_candidates.map { |kind, candidate| [kind, candidate ? dhis2_snapshots.find(candidate.id) : nil] }
                                      .to_h
    return nil if final_snapshots.values.compact.size != kinds.size
    new_pyramid(final_snapshots)
  end

  def nearest_data_compound_for(date)
    kinds = %i[data_elements data_element_groups indicators]
    pyramid_snapshots = dhis2_snapshots.select("id, year, month, kind").where(kind: kinds)

    candidates = pyramid_snapshots.sort_by { |snap| [snap.kind, [snap.year, snap.month].join("-")] }

    data_elements = nearest(candidates.select(&:kind_data_elements?), date)
    data_element_groups = nearest(candidates.select(&:kind_data_element_groups?), date)
    indicators = nearest(candidates.select(&:kind_indicators?), date)

    return nil unless data_elements || data_element_groups || indicators
    Rails.logger.info "for #{date} using snapshots #{data_elements.year} #{data_elements.month} and #{data_element_groups.year} #{data_element_groups.month} and #{indicators.year} #{indicators.month}"
    data_elements = dhis2_snapshots.find(data_elements.id) if data_elements
    data_element_groups = dhis2_snapshots.find(data_element_groups.id) if data_element_groups
    indicators = dhis2_snapshots.find(indicators.id) if indicators
    new_data_compound(data_elements, data_element_groups, indicators)
  end

  def nearest(snapshots, date)
    # there should be a better way
    time = date.to_time
    past_candidates = snapshots.select { |snapshot| snapshot.snapshoted_at <= date }
                               .sort_by { |snapshot| time - snapshot.snapshoted_at.to_time }

    past_candidate = past_candidates.first
    return past_candidate if past_candidate
    futur_candidates = snapshots.select { |snapshot| snapshot.snapshoted_at > date }
                                .sort_by do |snapshot|
                                  snapshot.snapshoted_at.to_time - time
                                end

    futur_candidates.first
  end

  def pyramid_for(date)
    kinds = %i[organisation_units organisation_unit_groups organisation_unit_group_sets]
    pyramid_snapshots = dhis2_snapshots
                        .where(kind: kinds)
                        .where(month: date.month)
                        .where(year: date.year)

    organisation_units = pyramid_snapshots.find(&:kind_organisation_units?)
    organisation_unit_groups = pyramid_snapshots.find(&:kind_organisation_unit_groups?)
    organisation_unit_group_sets = pyramid_snapshots.find(&:kind_organisation_unit_group_sets?)
    new_pyramid(
      organisation_units:           organisation_units,
      organisation_unit_groups:     organisation_unit_groups,
      organisation_unit_group_sets: organisation_unit_group_sets
    )
  end

  def new_data_compound(data_elements, data_element_groups, indicators)
    return nil unless data_elements && data_element_groups
    DataCompound.new(
      data_elements.content.map { |r| Dhis2::Api::DataElement.new(nil, r["table"]) },
      data_element_groups.content.map { |r| Dhis2::Api::DataElementGroup.new(nil, r["table"]) },
      indicators ? indicators.content.map { |r| Dhis2::Api::Indicator.new(nil, r["table"]) } : []
    )
  end

  def new_pyramid(orgs_data)
    Pyramid.new(
      orgs_data[:organisation_units].content.map do |r|
        Dhis2::Api::OrganisationUnit.new(nil, r["table"])
      end,
      orgs_data[:organisation_unit_groups].content.map do |r|
        Dhis2::Api::OrganisationUnitGroup.new(nil, r["table"])
      end,
      orgs_data[:organisation_unit_group_sets].content.map do |r|
        Dhis2::Api::OrganisationUnitGroupSet.new(nil, r["table"])
      end
    )
  end

  def data_compound_for(date)
    snapshots = dhis2_snapshots
                .where(kind: %i[data_elements data_element_groups indicators])
                .where(month: date.month)
                .where(year: date.year)

    data_elements = snapshots.find(&:kind_data_elements?)
    data_element_groups = snapshots.find(&:kind_data_element_groups?)
    indicators = snapshots.find(&:kind_indicators?)
    new_data_compound(data_elements, data_element_groups, indicators)
  end
end
