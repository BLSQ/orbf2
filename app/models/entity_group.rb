class EntityGroup < ApplicationRecord
  belongs_to :project
  validates :external_reference, presence: true
  validates :name, presence: true
end
