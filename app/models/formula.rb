class Formula
  include ActiveModel::Model
  attr_accessor :code, :expression, :label

  validates :code, presence: true, format: {
    with:    /[a-zA-Z_]+/,
    message: "only letters and _ like 'quality_score' or 'total_amount'"
  }

  validate :expression, :expression_is_valid

  def expression_is_valid
    Rules::Solver.new.validate_expression(self)
  end

end
