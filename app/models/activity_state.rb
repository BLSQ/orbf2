class ActivityState
  include ActiveModel::Model
  attr_accessor :id, :name, :state, :activity, :external_reference
end
