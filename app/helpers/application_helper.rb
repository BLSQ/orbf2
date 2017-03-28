module ApplicationHelper

  def d_to_s(decimal)
    return "%.2f" % decimal if decimal.is_a? Numeric
    decimal
  end
end
