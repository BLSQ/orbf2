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
#  kind                       :string           default("single")
#  ogs_reference              :string
#

class Package < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

  FREQUENCIES = %w[monthly quarterly yearly].freeze
  KINDS = %w[single multi-groupset].freeze
  belongs_to :project, inverse_of: :packages
  has_many :package_entity_groups, dependent: :destroy
  has_many :package_states, dependent: :destroy
  has_many :states, through: :package_states, source: :state
  has_many :rules, dependent: :destroy
  has_many :activity_packages, dependent: :destroy

  has_many :activities, through: :activity_packages, source: :activity

  validates :name, presence: true, length: { maximum: 50 }
  # validates :states, presence: true
  validates :frequency, presence: true, inclusion: {
    in:      FREQUENCIES,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  validates :kind, presence: true, inclusion: {
    in:      KINDS,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  accepts_nested_attributes_for :states

  attr_accessor :invoice_details

  def invoice_details
    states.select(&:activity_level?).map(&:code) + activity_rule.formulas.map(&:code) + ["activity_name"]
  end

  def package_state(state)
    package_states.find { |ps| ps.state_id == state.id }
  end

  def activity_states(state)
    activities.flat_map(&:activity_states).select { |activity_state| activity_state.state == state }
  end

  def periods(year_month, with_previous_year = true)
    periods = []
    if frequency == "monthly"
      periods << year_month
    elsif frequency == "quarterly"
      quarter = year_month.to_quarter
      periods << quarter
      periods << quarter.months
    end
    if frequency == "yearly" || project.cycle_yearly?
      year = year_month.to_year
      periods << year.months
      periods << year.quarters
      periods << year
    else
      raise "not supported"
    end

    if with_previous_year && activity_rule.used_variables_for_values.any? {|variable| variable.ends_with?("previous_year_values") }
      previous_year = year_month.minus_years(1).to_year
      periods  << previous_year.months.map {|yq| periods(yq, false) }
    end

    periods.flatten.uniq
  end

  def missing_rules_kind
    supported_rules_kind = %w[activity package]
    supported_rules_kind.delete("activity") if activity_rule
    supported_rules_kind.delete("package") if package_rule
    supported_rules_kind
  end

  def apply_for(entity)

    apply = configured? && package_entity_groups.any? { |group| entity.groups.include?(group.organisation_unit_group_ext_ref) }
    puts "#{name} : #{configured?} && #{apply}"
    apply
  end

  def configured?
    activity_rule && package_rule
  end

  def linked_org_units(org_unit, pyramid)
    if kind_multi?
      (pyramid.org_units_in_same_group(org_unit, ogs_reference).to_a + [org_unit]).uniq
    else
      [org_unit]
    end
  end

  def apply_for_org_unit(org_unit)
    group_ids = org_unit.organisation_unit_groups.map { |g| g["id"] }
    apply_to = package_entity_groups.any? { |group| group_ids.include?(group.organisation_unit_group_ext_ref) }
    apply_to
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

  def kind_multi?
    kind.start_with?("multi-")
  end

  def missing_activity_states
    missing_activity_states = {}
    activities.each do |activity|
      missing_states = states.select(&:activity_level?).map do |state|
        state unless activity.activity_state(state)
      end
      missing_activity_states[activity] = missing_states.reject(&:nil?)
    end
    missing_activity_states
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

  def to_unified_h
    {
      stable_id:             stable_id,
      name:                  name,
      states:                states.map do |state|
        { code: state.code }
      end,
      activity_packages:     Hash[
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
