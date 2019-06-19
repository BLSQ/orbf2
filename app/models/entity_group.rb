# == Schema Information
#
# Table name: entity_groups
#
#  id                              :bigint(8)        not null, primary key
#  external_reference              :string
#  limit_snaphot_to_active_regions :boolean          default(FALSE), not null
#  name                            :string
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  project_id                      :integer
#
# Indexes
#
#  index_entity_groups_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

class EntityGroup < ApplicationRecord
  include PaperTrailed
  belongs_to :project
  validates :external_reference, presence: true
  validates :name, presence: true

  delegate :program_id, to: :project
end
