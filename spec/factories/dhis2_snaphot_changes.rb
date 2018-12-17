# == Schema Information
#
# Table name: dhis2_snaphot_changes
#
#  id                :integer          not null, primary key
#  dhis2_id          :string           not null
#  dhis2_snapshot_id :integer
#  values_before     :jsonb
#  values_after      :jsonb
#  whodunnit         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :dhis2_snaphot_change do
    dhis2_id { "MyString" }
    dhis2_snapshot { nil }
    values_before { "" }
    values_after { "" }
    whodunnit { "MyString" }
  end
end
