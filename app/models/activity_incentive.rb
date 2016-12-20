class ActivityIncentive
  include ActiveModel::Model
  attr_accessor :value, :data_element_ext_ref

  validates :value, presence: true
  validates :name, presence: true

  def activity
    @activity ||= Activity.new
  end

  def external_reference=(external_reference)
    self.activity.external_reference = external_reference
  end

  def external_reference
    self.activity.external_reference
  end

  def name=(name)
    self.activity.name = name
  end

  def name
    self.activity.name
  end
end
