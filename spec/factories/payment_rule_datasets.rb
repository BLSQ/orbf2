# == Schema Information
#
# Table name: payment_rule_datasets
#
#  id                 :integer          not null, primary key
#  payment_rule_id    :integer
#  frequency          :string
#  external_reference :string
#  last_synched_at    :datetime
#  last_error         :string
#  desynchronized     :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :payment_rule_dataset do
    payment_rule { nil }
    frequency { "MyString" }
    external_reference { "MyString" }
    last_synched_at { "2018-06-22 11:37:49" }
    last_error { "MyString" }
    desynchronized { false }
  end
end
