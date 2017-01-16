# == Schema Information
#
# Table name: programs
#
#  id         :integer          not null, primary key
#  code       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :program do
    code Faker::Address.country
  end
end
