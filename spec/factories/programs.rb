# == Schema Information
#
# Table name: programs
#
#  id                  :bigint(8)        not null, primary key
#  code                :string           not null
#  oauth_client_secret :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  oauth_client_id     :string
#
# Indexes
#
#  index_programs_on_code  (code) UNIQUE
#

FactoryBot.define do
  factory :program do
    code { Faker::Address.country }
  end

  factory :program_with_project_anchor, parent: :program do
    project_anchor
  end
end
