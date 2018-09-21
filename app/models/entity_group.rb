# == Schema Information
#
# Table name: entity_groups
#
#  id                              :integer          not null, primary key
#  name                            :string
#  external_reference              :string
#  project_id                      :integer
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  limit_snaphot_to_active_regions :boolean          default(FALSE), not null
#

class EntityGroup < ApplicationRecord
  include PaperTrailed
  belongs_to :project
  validates :external_reference, presence: true
  validates :name, presence: true

  delegate :program_id, to: :project
end
