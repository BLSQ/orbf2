# == Schema Information
#
# Table name: projects
#
#  id                    :bigint(8)        not null, primary key
#  boolean               :boolean          default(FALSE)
#  bypass_ssl            :boolean          default(FALSE)
#  calendar_name         :string           default("gregorian"), not null
#  cycle                 :string           default("quarterly"), not null
#  default_aoc_reference :string
#  default_coc_reference :string
#  dhis2_logs_enabled    :boolean          default(TRUE), not null
#  dhis2_url             :string           not null
#  enabled               :boolean          default(TRUE), not null
#  engine_version        :integer          default(3), not null
#  invoice_app_path      :string           default("/api/apps/ORBF2---Invoices-and-Reports/index.html"), not null
#  name                  :string           not null
#  password              :string
#  publish_date          :datetime
#  publish_end_date      :datetime
#  qualifier             :string
#  read_through_deg      :boolean          default(TRUE), not null
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
    password { "password123" }
    bypass_ssl { false }
  end
end
