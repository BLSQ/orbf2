# == Schema Information
#
# Table name: project_anchors
#
#  id         :integer          not null, primary key
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :integer          not null
#
# Indexes
#
#  index_project_anchors_on_program_id  (program_id)
#
# Foreign Keys
#
#  fk_rails_...  (program_id => programs.id)
#

FactoryBot.define do
  factory :project_anchor do
  end
end
