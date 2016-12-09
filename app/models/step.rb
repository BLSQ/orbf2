class Step
  include ActiveModel::Model
  attr_accessor(:name, :status, :hint, :kind, :highlighted, :model)

  def todo?
    status == :todo
  end

  def done?
    status == :done
  end
end
