# == Schema Information
#
# Table name: package_states
#
#  id                     :integer          not null, primary key
#  de_external_reference  :string
#  deg_external_reference :string
#  ds_external_reference  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  package_id             :integer
#  state_id               :integer
#
# Indexes
#
#  index_package_states_on_package_id               (package_id)
#  index_package_states_on_package_id_and_state_id  (package_id,state_id) UNIQUE
#  index_package_states_on_state_id                 (state_id)
#  index_package_states_on_state_id_and_package_id  (state_id,package_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#  fk_rails_...  (state_id => states.id)
#

class PackageState < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :package
  delegate :program_id, to: :package
  belongs_to :package
  belongs_to :state
end
