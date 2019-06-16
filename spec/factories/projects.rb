# == Schema Information
#
# Table name: projects
#
#  id                    :integer          not null, primary key
#  boolean               :boolean          default(FALSE)
#  bypass_ssl            :boolean          default(FALSE)
#  cycle                 :string           default("quarterly"), not null
#  default_aoc_reference :string
#  default_coc_reference :string
#  dhis2_url             :string           not null
#  engine_version        :integer          default(3), not null
#  name                  :string           not null
#  password              :string
#  publish_date          :datetime
#  qualifier             :string
#  status                :string           default("draft"), not null
#  user                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  original_id           :integer
#  project_anchor_id     :integer
#
# Indexes
#
#  index_projects_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (original_id => projects.id)
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :project do
    name { Faker::Address.country }
    dhis2_url { Faker::Internet.url }
    user { Faker::Internet.user_name }
    password { Faker::Internet.password(8) }
    bypass_ssl { false }
  end
end
