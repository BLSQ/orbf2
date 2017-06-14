# == Schema Information
#
# Table name: package_states
#
#  id                     :integer          not null, primary key
#  package_id             :integer
#  state_id               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  ds_external_reference  :string
#  deg_external_reference :string
#  de_external_reference  :string
#

class PackageState < ApplicationRecord
  belongs_to :package
  belongs_to :state
  has_paper_trail
end
