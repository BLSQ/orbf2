# == Schema Information
#
# Table name: packages
#
#  id                         :bigint(8)        not null, primary key
#  data_element_group_ext_ref :string           not null
#  deg_external_reference     :string
#  description                :string
#  frequency                  :string           not null
#  groupsets_ext_refs         :string           default([]), is an Array
#  include_main_orgunit       :boolean          default(FALSE), not null
#  kind                       :string           default("single")
#  name                       :string           not null
#  ogs_reference              :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  loop_over_combo_ext_id     :string
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
