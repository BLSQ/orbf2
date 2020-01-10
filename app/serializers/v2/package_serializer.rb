# frozen_string_literal: true

class V2::PackageSerializer
  include FastJsonapi::ObjectSerializer
  set_type :set

  attributes :name
  attributes :description
  attributes :frequency
  attributes :kind
  attributes :include_main_orgunit
  attributes :loop_over_combo_ext_id
  attributes :data_element_group_ext_ref

  has_many :org_unit_groups, serializer: V2::DhisValueItemSerializer do |package|
    package.main_entity_groups.map do |group|
      Struct.new(:id, :type, :value, :display_name).new(group.organisation_unit_group_ext_ref, "organisation_unit_group", group.organisation_unit_group_ext_ref, group.name)
    end
  end

  has_many :org_unit_group_sets, serializer: V2::DhisValueItemSerializer do |package|
    package.org_unit_group_sets
  end

  has_many :inputs, serializer: V2::StateSerializer do |package|
    package.states
  end

  has_many :topic_formulas do |package|
    package.activity_rule.formulas
  end

  has_many :topics, serializer: V2::ActivitySerializer do |package|
    package.activities
  end
end
