class ActivityIncentive
  include ActiveModel::Model
  attr_accessor :activity, :value

  validates :value, presence: true
end
