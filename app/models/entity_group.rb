# == Schema Information
#
# Table name: entity_groups
#
#  id                 :integer          not null, primary key
#  name               :string
#  external_reference :string
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class EntityGroup < ApplicationRecord
  include PaperTrailed
  belongs_to :project
  validates :external_reference, presence: true
  validates :name, presence: true

  delegate :program_id, to: :project

  def find_sibling_organisation_unit_groups
    dhis2 = project.dhis2_connection
    units = dhis2.organisation_units.list(
      page_size: 50_000,
      fields:    "id,displayName,organisationUnitGroups"
    )

    group_ids = units.reject { |unit| unit.organisation_unit_groups.nil? }
                     .select { |unit| unit.organisation_unit_groups.any? { |g| g["id"] == external_reference } }
                     .map(&:organisation_unit_groups)
                     .flatten
                     .map { |g| g["id"] }
                     .uniq

    group_ids -= [external_reference]
    dhis2.organisation_unit_groups.find(group_ids).uniq
  end
end
