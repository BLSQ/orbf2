class Activity < ApplicationRecord
  belongs_to :project, inverse_of: :activities
  has_many :activity_states, dependent: :destroy
end
