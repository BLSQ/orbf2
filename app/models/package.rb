# frozen_string_literal: true
# == Schema Information
#
# Table name: packages
#
#  id                         :integer          not null, primary key
#  data_element_group_ext_ref :string           not null
#  frequency                  :string           not null
#  groupsets_ext_refs         :string           default([]), is an Array
#  include_main_orgunit       :boolean          default(FALSE), not null
#  kind                       :string           default("single")
#  name                       :string           not null
#  ogs_reference              :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  project_id                 :integer
#  stable_id                  :uuid             not null
#
# Indexes
#
#  index_packages_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

class Package < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

  FREQUENCIES = %w[monthly quarterly yearly].freeze
  KINDS = %w[single multi-groupset zone].freeze
  belongs_to :project, inverse_of: :packages
  has_many :package_entity_groups, dependent: :destroy
  has_many :package_states, dependent: :destroy
  has_many :states, through: :package_states, source: :state
  has_many :rules, dependent: :destroy
  has_many :activity_packages, dependent: :destroy

  has_many :activities, -> { order(code: :asc) }, through: :activity_packages, source: :activity

  validates :name, presence: true, length: { maximum: 50 }

  validates :frequency, presence: true, inclusion: {
    in:      FREQUENCIES,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  validates :kind, presence: true, inclusion: {
    in:      KINDS,
    message: "%{value} is not a valid see #{KINDS.join(',')}"
  }

  accepts_nested_attributes_for :states

  def code
    @code ||= Orbf::RulesEngine::Codifier.codify(name)
  end

  def invoice_details
    states.map(&:code) + activity_rule.formulas.map(&:code) + ["activity_name"]
  end

  def package_state(state)
    package_states.find { |ps| ps.state_id == state.id }
  end

  def activity_states(state)
    activities.flat_map(&:activity_states).select { |activity_state| activity_state.state == state }
  end

  def monthly?
    frequency == "monthly"
  end

  def quarterly?
    frequency == "quarterly"
  end

  def yearly?
    frequency == "yearly"
  end

  def multi_entities?
    kind == "multi-groupset"
  end

  def zone_kind?
    kind == "zone"
  end

  def missing_rules_kind
    %w[activity package multi-entities zone zone_activity] - rules.map(&:kind)
  end

  def allowed_rules
    allowed_rules = [
      Rule::RULE_TYPE_PAYMENT,
      Rule::RULE_TYPE_ACTIVITY,
      Rule::RULE_TYPE_PACKAGE,
      Rule::RULE_TYPE_MULTI_ENTITIES
    ]
    if zone_kind?
      allowed_rules << Rule::RULE_TYPE_ZONE
      allowed_rules << Rule::RULE_TYPE_ZONE_ACTIVITY
    end
    allowed_rules
  end

  def rule_allowed?(rule_kind:)
    allowed_rules.include?(rule_kind)
  end

  def already_has_rule?(rule_kind:)
    rules.where(kind: rule_kind).any?
  end

  def configured?
    activity_rule && package_rule
  end

  def for_frequency(frequency_to_apply)
    frequency_to_apply == frequency
  end

  def multi_entities_rule
    rules.find(&:multi_entities_kind?)
  end

  def package_rule
    rules.find(&:package_kind?)
  end

  def activity_rule
    rules.find(&:activity_kind?)
  end

  def zone_activity_rule
    rules.find(&:zone_activity_kind?)
  end

  def zone_rule
    rules.find(&:zone_kind?)
  end

  def kind_multi?
    kind.start_with?("multi-")
  end

  def main_entity_groups
    package_entity_groups.select(&:main?)
  end

  def target_entity_groups
    package_entity_groups.select(&:target?)
  end

  def missing_activity_states
    missing_activity_states = {}
    activities.each do |activity|
      missing_states = states.map do |state|
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
    created_deg
  rescue RestClient::Exception => e
    raise "Failed to create data element group #{deg} #{e.message} with #{project.dhis2_url}"
  end

  def create_package_entity_groups(main_entity_groups_ids, target_entity_groups_ids)
    dhis2 = project.dhis2_connection
    all_group_ids = (main_entity_groups_ids || []) + (target_entity_groups_ids || [])
    organisation_unit_groups = dhis2.organisation_unit_groups.find(all_group_ids)

    organisation_unit_groups.map do |organisation_unit_group|
      belong_to_main = main_entity_groups_ids.include?(organisation_unit_group.id)
      {
        name:                            organisation_unit_group.display_name,
        kind:                            belong_to_main ? "main" : "target",
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
