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
#  groupsets_ext_refs         :string           default([]), is an Array
#

FactoryBot.define do
  factory :package do
  end
end
