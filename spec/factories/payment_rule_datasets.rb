# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment_rule_dataset do
    payment_rule nil
    frequency "MyString"
    external_reference "MyString"
    last_synched_at "2018-06-22 11:37:49"
    last_error "MyString"
    desynchronized false
  end
end
