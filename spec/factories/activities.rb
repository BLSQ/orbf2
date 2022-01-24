# frozen_string_literal: true

# == Schema Information
#
# Table name: activities
#
#  id         :bigint(8)        not null, primary key
#  code       :string
#  name       :string           not null
#  short_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#  stable_id  :uuid             not null
#
# Indexes
#
#  index_activities_on_name_and_project_id  (name,project_id) UNIQUE
#  index_activities_on_project_id           (project_id)
#  index_activities_on_project_id_and_code  (project_id,code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

FactoryBot.define do
  factory :activity do
  end
end
