# == Schema Information
#
# Table name: packages
#
#  id                         :integer          not null, primary key
#  name                       :string           not null
#  data_element_group_ext_ref :string           not null
#  frequency                  :string           not null
#  project_id                 :integer
#

class Package < ApplicationRecord
  FREQUENCIES = %w(monthly quarterly).freeze
  belongs_to :project
  has_many :package_states
  has_many :states, through: :package_states
  validates :name, presence: true, length: { maximum: 230 }
  # validates :states, presence: true
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
end
