class ActivityState < ApplicationRecord
  belongs_to :activity, inverse_of: :activity_states
  has_one :state
end
