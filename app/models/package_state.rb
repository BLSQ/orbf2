# == Schema Information
#
# Table name: package_states
#
#  id         :integer          not null, primary key
#  package_id :integer
#  state_id   :integer
#

class PackageState < ApplicationRecord
  belongs_to :package
  belongs_to :state
end
