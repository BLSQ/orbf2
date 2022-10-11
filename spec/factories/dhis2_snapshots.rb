# == Schema Information
#
# Table name: dhis2_snapshots
#
#  id                :integer          not null, primary key
#  content           :jsonb            not null
#  dhis2_version     :string           not null
#  kind              :string           not null
#  month             :integer          not null
#  year              :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  job_id            :string           not null
#  project_anchor_id :integer
#
# Indexes
#
#  index_dhis2_snapshots_on_project_anchor_id  (project_anchor_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :dhis2_snapshot do
    kind { "MyString" }
    content { "" }
    project_anchor { nil }
    dhis2_version { "MyString" }
    year { 1 }
    month { 1 }
    job_id { "MyString" }
  end
end
