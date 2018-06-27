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
#  frequency   :string
#  short_name  :string
#

class Formula < ApplicationRecord
  FREQUENCIES = %w[monthly quarterly yearly].freeze
  include PaperTrailed
  REGEXP_VALIDATION = /\A[a-z_0-9]+\z/
  delegate :project_id, to: :rule
  delegate :program_id, to: :rule

  belongs_to :rule, inverse_of: :formulas

  has_many :formula_mappings, dependent: :destroy, inverse_of: :formula

  validates :code, presence: true, format: {
    with:    REGEXP_VALIDATION,
    message: ": should only contains lowercase letters and _ like 'quality_score' or 'total_amount' vs %{value}"
  }

  validates :frequency, presence: false, if: proc { |f| f.frequency.present? }, inclusion: {
    in:      FREQUENCIES,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  validates :description, presence: true
  validates :expression, presence: true
  validate :expression, :expression_is_valid

  def frequency=(val)
    striped = val.strip
    super(striped.blank? ? nil : striped)
  end

  def expression_is_valid
    @solver ||= Rules::Solver.new
    @solver.validate_expression(self) if code && description
  end

  def dependencies
    values_dependencies + Rules::Solver.new.dependencies(self)
  end

  def values_dependencies
    rule.available_variables_for_values.select do |values|
      expression && expression.include?("%{#{values}}")
    end
  end

  def find_or_build_mapping(mapping_attributes)
    existing_mapping = formula_mappings.detect do |mapping|
      mapping.kind == mapping_attributes[:kind] &&
        (mapping_attributes[:activity] ? mapping.activity == mapping_attributes[:activity] : true)
    end
    existing_mapping || formula_mappings.build(mapping_attributes)
  end

  def has_mappings?
    formula_mappings.any?
  end

  def formula_mapping(activity = nil)
    formula_mappings.find { |mapping| mapping.activity == activity }
  end
end
