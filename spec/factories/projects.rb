# == Schema Information
#
# Table name: projects
#
#  id                :integer          not null, primary key
#  name              :string           not null
#  dhis2_url         :string           not null
#  user              :string
#  password          :string
#  bypass_ssl        :boolean          default(FALSE)
#  boolean           :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  status            :string           default("draft"), not null
#  publish_date      :datetime
#  project_anchor_id :integer
#  original_id       :integer
#  cycle             :string           default("quarterly"), not null
#  engine_version    :integer          default(1), not null
#  qualifier         :string
#

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
