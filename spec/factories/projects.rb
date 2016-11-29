# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project do
    name Faker::Address.country
    dhis2_url Faker::Internet.url
    user Faker::Internet.user_name
    password Faker::Internet.password(8)
    bypass_ssl false
  end
end
