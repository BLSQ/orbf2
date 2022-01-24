# frozen_string_literal: true

# == Schema Information
#
# Table name: states
#
#  id         :bigint(8)        not null, primary key
#  name       :string           not null
#  short_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#
# Indexes
#
#  index_states_on_project_id           (project_id)
#  index_states_on_project_id_and_name  (project_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

FactoryBot.define do
  factory :state do
  end
end
