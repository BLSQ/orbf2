# frozen_string_literal: true

class V2::PackageSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name
  attributes :description
  attributes :frequency
  attributes :kind
  attributes :include_main_orgunit
  attributes :loop_over_combo_ext_id
  attributes :data_element_group_ext_ref

  has_many :topic_formulas do |package|
    package.activity_rule.formulas
  end

  has_many :topics do |package|
    package.activities
  end
end
