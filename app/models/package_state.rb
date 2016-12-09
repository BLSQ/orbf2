# == Schema Information
#
# Table name: package_states
#
#  id         :integer          not null, primary key
#  package_id :integer
#  state_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PackageState < ApplicationRecord
  belongs_to :package
  belongs_to :state
end
