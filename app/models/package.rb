# == Schema Information
#
# Table name: packages
#
#  id                         :integer          not null, primary key
#  name                       :string           not null
#  data_element_group_ext_ref :string           not null
#  frequency                  :string           not null
#  project_id                 :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  stable_id                  :uuid             not null
#

class Package < ApplicationRecord
  FREQUENCIES = %w(monthly quarterly).freeze
  belongs_to :project, inverse_of: :packages
  has_many :package_entity_groups, dependent: :destroy
  has_many :package_states, dependent: :destroy
  has_many :states, through: :package_states
  has_many :rules, dependent: :destroy
  has_many :activity_packages, dependent: :destroy

  has_many :activities, through: :activity_packages

  validates :name, presence: true, length: { maximum: 50 }
  # validates :states, presence: true
  validates :frequency, presence: true, inclusion: {
    in:      FREQUENCIES,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  accepts_nested_attributes_for :states

  attr_accessor :invoice_details

  def missing_rules_kind
    supported_rules_kind = %w(activity package)
    supported_rules_kind.delete("activity") if activity_rule
    supported_rules_kind.delete("package") if package_rule
    supported_rules_kind
  end

  def apply_for(entity)
    package_entity_groups.any? { |group| entity.groups.include?(group.organisation_unit_group_ext_ref) }
  end

  def for_frequency(frequency_to_apply)
    frequency_to_apply == frequency
  end

  def package_rule
    rules.find { |r| r.kind == "package" }
  end

  def activity_rule
    rules.find { |r| r.kind == "activity" }
  end

  def create_data_element_group(data_element_ids)
    deg = [
      { name:          name,
        short_name:    name[0..49],
        code:          name[0..49],
        display_name:  name,
        data_elements: data_element_ids.map do |data_element_id|
          { id: data_element_id }
        end }
    ]
    dhis2 = project.dhis2_connection
    status = dhis2.data_element_groups.create(deg)
    created_deg = dhis2.data_element_groups.find_by(name: name)
    raise "data element group not created #{name} : #{deg} : #{status.inspect}" unless created_deg
    return created_deg
  rescue RestClient::Exception => e
    raise "Failed to create data element group #{deg} #{e.message} with #{project.dhis2_url}"
  end

  def create_package_entity_groups(entity_group_ids)
    dhis2 = project.dhis2_connection
    organisation_unit_groups = dhis2.organisation_unit_groups.find(entity_group_ids)

    organisation_unit_groups.map do |organisation_unit_group|
      {
        name:                            organisation_unit_group.display_name,
        organisation_unit_group_ext_ref: organisation_unit_group.id
      }
    end
  end

  # will fetch the activities of a given package id (data_element_group_ext_ref)
  def fetch_activities
    dhis2 = project.dhis2_connection
    activities = dhis2.data_elements.list(filter: "dataElementGroups.id:eq:#{data_element_group_ext_ref}").map do |dataelement|
      ActivityForm.new(
        external_reference: dataelement.id,
        name:               dataelement.display_name
      )
    end
  end

  def to_unified_h
    {
      stable_id:             stable_id,
      name:                  name,
      states:                states.map do |state|
        { code: state.code }
      end,
      activity_packages: Hash[
        activity_packages.flat_map(&:activity).map(&:to_unified_h).map do |activity|
          [activity[:stable_id], activity]
        end
      ],
      package_entity_groups: package_entity_groups.map do |entity_group|
        {
          external_reference: entity_group.organisation_unit_group_ext_ref,
          name:               name
        }
      end,

      rules:                 Hash[
        rules.map(&:to_unified_h).map do |rule|
          [rule[:stable_id], rule]
        end
      ]
    }
  end

  def to_s
    "Package-#{id}-#{name}"
  end
end
