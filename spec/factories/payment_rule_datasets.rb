# == Schema Information
#
# Table name: payment_rule_datasets
#
#  id                 :integer          not null, primary key
#  desynchronized     :boolean
#  external_reference :string
#  frequency          :string
#  last_error         :string
#  last_synched_at    :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  payment_rule_id    :integer
#
# Indexes
#
#  index_payment_rule_datasets_on_payment_rule_id                (payment_rule_id)
#  index_payment_rule_datasets_on_payment_rule_id_and_frequency  (payment_rule_id,frequency) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (payment_rule_id => payment_rules.id)
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
