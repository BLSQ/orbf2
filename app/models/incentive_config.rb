class IncentiveConfig
  include ActiveModel::Model
  attr_accessor :id, :state, :package, :entity_groups, :activity_incentives, :start_date, :end_date, :project

  validates :package, presence: true
  validates :state, presence: true
  # validates :entity_groups, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def initialize(attributes = {})
    super
    self.entity_groups = attributes[:entity_groups] unless attributes.nil?
    self.activity_incentives_attributes = attributes[:activity_incentives_attributes] if attributes && attributes[:activity_incentives_attributes]
  end

  def activity_incentives_attributes=(activity_incentives_attributes)
    self.activity_incentives = []
    activity_incentives_attributes.values.each do |att|
      activity_incentives << ActivityIncentive.new(att)
    end
  end
end
