# == Schema Information
#
# Table name: rules
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  kind       :string           not null
#  package_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer
#

class Rule < ApplicationRecord
  RULE_TYPES = %w(payment activity package).freeze
  belongs_to :package, optional: true, inverse_of: :rules
  belongs_to :project, optional: true, inverse_of: :rules

  has_many :formulas, dependent: :destroy, inverse_of: :rule

  accepts_nested_attributes_for :formulas, reject_if: :all_blank, allow_destroy: true

  validates :kind, presence: true, inclusion: {
    in:      RULE_TYPES,
    message: "%{value} is not a valid see #{RULE_TYPES.join(',')}"
  }
  validates :name, presence: true
  validates :formulas, length: { minimum: 1 }
  validate :formulas, :formulas_are_coherent

  def activity_kind?
    kind == "activity"
  end

  def package_kind?
    kind == "package"
  end

  def payment_kind?
    kind == "payment"
  end

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = Rules::Solver.escapeString(name)
    facts
  end

  def formulas_are_coherent
    Rules::Solver.new.validate_formulas(self) if name
  end

  def available_variables
    var_names = []
    if activity_kind?
      var_names << package.states.select(&:activity_level?).map(&:code) if package
      var_names << formulas.map(&:code)
    elsif package_kind?
      var_names << package.states.select(&:package_level?).map(&:code) if package
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }
    elsif payment_kind?
      rules = project.packages.flat_map(&:rules).select(&:package_kind?)
      var_names << rules.flat_map(&:formulas).map(&:code)
    end
    var_names.flatten.uniq.reject(&:nil?).sort
  end

  def available_variables_for_values
    var_names = []
    if kind == "package" && package.activity_rule
      var_names << package.activity_rule.formulas.map(&:code).map { |code| "#{code}_values" }
    end
    var_names.flatten
  end

  def fake_facts
    if activity_kind?
      {
        claimed:   "1.0",
        verified:  "1.0",
        declared:  "1.0",
        validated: "1.0",
        tarif:     "100",
        max_score: "100"
      }
    elsif package_kind?
      {
        budget: "10000"
      }
    elsif payment_kind?
      facts = {}
      rules = project.packages.flat_map(&:rules).select(&:package_kind?)
      rules.flat_map(&:formulas).each do |formula|
        facts[formula.code] = "1040.1"
      end
      facts
    end
  end
end
