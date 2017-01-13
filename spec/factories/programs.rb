FactoryGirl.define do
  factory :program do
    code Faker::Address.country
  end
end
