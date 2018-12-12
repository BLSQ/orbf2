# == Schema Information
#
# Table name: packages
#
#  id                         :integer          not null, primary key
#  data_element_group_ext_ref :string           not null
#  frequency                  :string           not null
#  groupsets_ext_refs         :string           default([]), is an Array
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

FactoryBot.define do
  factory :package do
  end
end
