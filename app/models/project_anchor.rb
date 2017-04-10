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
    pyramid_snapshots = dhis2_snapshots.select("id, year, month, kind").where(kind: [:organisation_units, :organisation_unit_groups])

    candidates = pyramid_snapshots.sort_by { |snap| [snap.kind, [snap.year, snap.month].join("-")] }

    organisation_units = nearest(candidates.select(&:kind_organisation_units?), date)
    organisation_unit_groups = nearest(candidates.select(&:kind_organisation_unit_groups?), date)

    puts "for #{date} using snapshots #{organisation_units.year} #{organisation_units.month} and #{organisation_unit_groups.year} #{organisation_unit_groups.month}"
    organisation_units = dhis2_snapshots.find(organisation_units.id) if organisation_units
    organisation_unit_groups = dhis2_snapshots.find(organisation_unit_groups.id) if organisation_unit_groups
    new_pyramid(organisation_units, organisation_unit_groups)
  end

  def nearest_data_compound_for(date)
    pyramid_snapshots = dhis2_snapshots.select("id, year, month, kind").where(kind: [:data_elements, :data_element_groups, :indicators])

    candidates = pyramid_snapshots.sort_by { |snap| [snap.kind, [snap.year, snap.month].join("-")] }

    data_elements = nearest(candidates.select(&:kind_data_elements?), date)
    data_element_groups = nearest(candidates.select(&:kind_data_element_groups?), date)
    indicators = nearest(candidates.select(&:kind_indicators?), date)

    puts "for #{date} using snapshots #{data_elements.year} #{data_elements.month} and #{data_element_groups.year} #{data_element_groups.month} and #{indicators.year} #{indicators.month}"
    data_elements = dhis2_snapshots.find(data_elements.id) if data_elements
    data_element_groups = dhis2_snapshots.find(data_element_groups.id) if data_element_groups
    indicators = dhis2_snapshots.find(indicators.id) if indicators
    new_data_compound(data_elements, data_element_groups, indicators)
  end

  def nearest(snapshots, date)
    # there should be a better way

    past_candidates = snapshots.select { |snapshot| snapshot.snapshoted_at <= date }
                               .sort_by { |snapshot| date - snapshot.snapshoted_at }

    past_candidate = past_candidates.first
    return past_candidate if past_candidate
    futur_candidates = snapshots.select { |snapshot| snapshot.snapshoted_at > date }
                                .sort_by { |snapshot| snapshot.snapshoted_at - date }

    futur_candidates.first
  end

  def pyramid_for(date)
    pyramid_snapshots = dhis2_snapshots
                        .where(kind: [:organisation_units, :organisation_unit_groups])
                        .where(month: date.month)
                        .where(year: date.year)

    organisation_units = pyramid_snapshots.find(&:kind_organisation_units?)
    organisation_unit_groups = pyramid_snapshots.find(&:kind_organisation_unit_groups?)
    new_pyramid(organisation_units, organisation_unit_groups)
  end

  def new_data_compound(data_elements, data_element_groups, indicators)
    return nil unless data_elements && data_element_groups
    DataCompound.new(
      data_elements.content.map { |r| Dhis2::Api::DataElement.new(nil, r["table"]) },
      data_element_groups.content.map { |r| Dhis2::Api::DataElementGroup.new(nil, r["table"]) },
      indicators ? indicators.content.map { |r| Dhis2::Api::Indicator.new(nil, r["table"]) } : []
    )
  end

  def new_pyramid(organisation_units, organisation_unit_groups)
    return nil unless organisation_units && organisation_unit_groups
    Pyramid.new(
      organisation_units.content.map { |r| Dhis2::Api::OrganisationUnit.new(nil, r["table"]) },
      organisation_unit_groups.content.map { |r| Dhis2::Api::OrganisationUnitGroup.new(nil, r["table"]) }
    )
  end

  def data_compound_for(date)
    snapshots = dhis2_snapshots
                .where(kind: [:data_elements, :data_element_groups, :indicators])
                .where(month: date.month)
                .where(year: date.year)

    data_elements = snapshots.find(&:kind_data_elements?)
    data_element_groups = snapshots.find(&:kind_data_element_groups?)
    indicators = snapshots.find(&:kind_indicators?)
    new_data_compound(data_elements, data_element_groups, indicators)
  end
end
