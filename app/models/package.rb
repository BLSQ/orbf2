class Package < ApplicationRecord
  belongs_to :project
  validates :name, presence: true
  validates :data_element_group_ext_ref, presence: true
  validates :frequency, presence: true
end
