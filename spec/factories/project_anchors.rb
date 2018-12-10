# == Schema Information
#
# Table name: project_anchors
#
#  id         :integer          not null, primary key
#  program_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  token      :string
#

FactoryBot.define do
  factory :project_anchor do
  end
end
