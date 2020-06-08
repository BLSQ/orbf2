# == Schema Information
#
# Table name: entity_groups
#
#  id                              :bigint(8)        not null, primary key
#  all_event_sql_view_reference    :string
#  external_reference              :string
#  kind                            :string           default("group_based")
#  limit_snaphot_to_active_regions :boolean          default(FALSE), not null
#  name                            :string
#  program_reference               :string
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

  class Kinds
    GROUP_BASED = "group_based"
    CONTRACT_PROGRAM_BASED = "contract_program_based"
    OPTIONS = [
      ["Group based", Kinds::GROUP_BASED],
      ["Contract program based", Kinds::CONTRACT_PROGRAM_BASED]
    ]
  end

  include PaperTrailed

  belongs_to :project
  validates :external_reference, presence: true, if: :group_based?
  validates :name, presence: true, if: :group_based?
  validates :program_reference, presence: true, if:  :contract_program_based?
  validates :all_event_sql_view_reference, presence: true, if:  :contract_program_based?

  delegate :program_id, to: :project

  def group_based?
    kind == Kinds::GROUP_BASED
  end

  def contract_program_based?
    kind == Kinds::CONTRACT_PROGRAM_BASED
  end

end
