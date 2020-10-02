# frozen_string_literal: true

class V2::PackageSerializer < V2::BaseSerializer
  set_type :set

  attributes :name
  attributes :description
  attributes :frequency
  attributes :kind
  attributes :include_main_orgunit
  attributes :loop_over_combo_ext_id
  attributes :data_element_group_ext_ref

  belongs_to :simulation_org_unit,
             serializer: V2::OrgUnitSerializer,
             if:         proc { |_record, params| (params || {}).fetch(:with_sim_org_unit, false) } do |package|
    package.simulation_org_unit
  end

  has_many :org_unit_groups, serializer: V2::OrgUnitGroupSerializer do |package|
    package.main_entity_groups.map do |group|
      Struct.new(:id, :value, :display_name).new(group.organisation_unit_group_ext_ref, group.organisation_unit_group_ext_ref, group.name)
    end
  end

  has_many :org_unit_group_sets, serializer: V2::OrgUnitGroupSetSerializer do |package|
    package.org_unit_group_sets.map do |group_set_data|
      Struct.new(:id, :value, :display_name).new(
        group_set_data[:id],
        group_set_data[:id],
        group_set_data[:display_name]
      )
    end
  end

  has_many :inputs, serializer: V2::StateSerializer do |package|
    package.states
  end

  has_many :topic_formulas, serializer: V2::FormulaSerializer, record_type: :formula  do |package|
    package.activity_rule&.formulas
  end

  has_many :set_formulas, serializer: V2::FormulaSerializer, record_type: :formula  do |package|
    package.package_rule&.formulas
  end

  has_many :zone_topic_formulas, serializer: V2::FormulaSerializer, record_type: :formula  do |package|
    package.zone_activity_rule&.formulas
  end

  has_many :zone_formulas, serializer: V2::FormulaSerializer, record_type: :formula  do |package|
    package.zone_rule&.formulas
  end

  has_many :multi_entities_formulas, serializer: V2::FormulaSerializer, record_type: :formula  do |package|
    package.multi_entities_rule&.formulas
  end

  has_many :topics, serializer: V2::ActivitySerializer do |package|
    package.activities
  end
end
