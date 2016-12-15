class Formula
  include ActiveModel::Model
  attr_accessor :code, :expression, :label

  validates :code, presence: true, format: {
    with:    /\A[a-z_]+\z/,
    message: ": should only contains small letters and _ like 'quality_score' or 'total_amount'"
  }

  validate :expression, :expression_is_valid

  def expression_is_valid
    Rules::Solver.new.validate_expression(self)
  end
end
