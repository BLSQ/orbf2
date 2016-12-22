class IncentiveConfig
  include ActiveModel::Model
  attr_accessor :id, :state, :package, :entity_groups, :activity_incentives, :start_date, :end_date, :project, :entities

  validates :package, presence: true
  validates :state, presence: true
  # validates :entity_groups, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def initialize(attributes = {})
    super
    self.entity_groups = attributes[:entity_groups] unless attributes.nil?
    self.activity_incentives = attributes[:activity_incentives] if attributes && attributes[:activity_incentives]
  end

  def activity_incentives_attributes=(activity_incentives)
    self.activity_incentives = []
    activity_incentives.values.each do |att|
      activity_incentives << ActivityIncentive.new(att)
    end
  end
end
