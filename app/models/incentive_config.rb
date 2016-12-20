class IncentiveConfig
  include ActiveModel::Model
  attr_accessor :id, :package, :state, :entity_groups, :activity_incentives, :start_date, :end_date

  validates :package, presence: true
  validates :state, presence: true
  # validates :entity_groups, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def initialize(attributes = {})
    super
    self.id = nil
    self.entity_groups = attributes[:entity_groups] unless attributes.empty?
  end

  def persisted?
    false
  end
end
