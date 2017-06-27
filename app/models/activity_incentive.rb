class ActivityIncentive
  include ActiveModel::Model
  attr_accessor :value, :data_element_ext_ref

  validates :value, presence: true
  validates :name, presence: true

  def activity
    @activity ||= ActivityForm.new
  end

  delegate :external_reference=, to: :activity

  delegate :external_reference, to: :activity

  delegate :name=, to: :activity

  delegate :name, to: :activity
end
