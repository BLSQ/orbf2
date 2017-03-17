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
    projects.where(status: "draft").last
  end

  def pyramid_for(date)
    pyramid_snapshots = dhis2_snapshots
                        .where(kind: [:organisation_units, :organisation_unit_groups])
                        .where(month: date.month)
                        .where(year: date.year)

    organisation_units = pyramid_snapshots.find(&:kind_organisation_units?)
    organisation_unit_groups = pyramid_snapshots.find(&:kind_organisation_unit_groups?)
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
    return nil unless data_elements && data_element_groups
    DataCompound.new(
      data_elements.content.map { |r| Dhis2::Api::DataElement.new(nil, r["table"]) },
      data_element_groups.content.map { |r| Dhis2::Api::DataElementGroup.new(nil, r["table"]) },
      indicators ? indicators.content.map { |r| Dhis2::Api::Indicator.new(nil, r["table"]) } : []
    )
  end
end
