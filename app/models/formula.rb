# == Schema Information
#
# Table name: formulas
#
#  id          :integer          not null, primary key
#  code        :string           not null
#  description :string           not null
#  expression  :text             not null
#  rule_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Formula < ApplicationRecord
  belongs_to :rule, inverse_of: :formulas
  validates :code, presence: true, format: {
    with:    /\A[a-z_]+\z/,
    message: ": should only contains small letters and _ like 'quality_score' or 'total_amount'"
  }

  validates :description, presence: true
  validates :expression, presence: true
  validate :expression, :expression_is_valid

  def expression_is_valid
    Rules::Solver.new.validate_expression(self) if code && description
  end


  def dependencies
    values_dependencies = rule.available_variables_for_values.select do |values|
      expression.include?("%{#{values}}")
    end
    values_dependencies + Rules::Solver.new.dependencies(self)
  end
end
