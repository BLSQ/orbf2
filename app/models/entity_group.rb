# == Schema Information
#
# Table name: entity_groups
#
#  id                 :integer          not null, primary key
#  name               :string
#  external_reference :string
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class EntityGroup < ApplicationRecord
  belongs_to :project
  validates :external_reference, presence: true
  validates :name, presence: true
end
