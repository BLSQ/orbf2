# frozen_string_literal: true

# == Schema Information
#
# Table name: rules
#
#  id              :bigint(8)        not null, primary key
#  kind            :string           not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  package_id      :integer
#  payment_rule_id :integer
#  stable_id       :uuid             not null
#
# Indexes
#
#  index_rules_on_package_id       (package_id)
#  index_rules_on_payment_rule_id  (payment_rule_id)
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#  fk_rails_...  (payment_rule_id => payment_rules.id)
#

class Rule < ApplicationRecord
  include PaperTrailed
  RULE_TYPE_MULTI_ENTITIES = "multi-entities"
  RULE_TYPE_ACTIVITY = "activity"
  RULE_TYPE_PACKAGE = "package"
  RULE_TYPE_PAYMENT = "payment"
  RULE_TYPE_ZONE = "zone"
  RULE_TYPE_ZONE_ACTIVITY = "zone_activity"

  RULE_TYPES = [
    RULE_TYPE_PAYMENT, RULE_TYPE_ACTIVITY,
    RULE_TYPE_PACKAGE, RULE_TYPE_MULTI_ENTITIES,
    RULE_TYPE_ZONE, RULE_TYPE_ZONE_ACTIVITY
  ].freeze

  belongs_to :package, optional: true, inverse_of: :rules
  belongs_to :payment_rule, optional: true, inverse_of: :rule

  has_many :formulas, dependent: :destroy, inverse_of: :rule
  has_many :decision_tables, dependent: :destroy, inverse_of: :rule

  accepts_nested_attributes_for :formulas, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :decision_tables, reject_if: :all_blank, allow_destroy: true

  validates :kind, presence: true, inclusion: {
    in:      RULE_TYPES,
    message: "%{value} is not a valid see #{RULE_TYPES.join(',')}"
  }
  validates :name, presence: true
  validates :formulas, length: { minimum: 1 }, unless: :multi_entities_kind?
  validate :formulas, :formulas_are_coherent

  validate :formulas, :package_formula_uniqness

  def sorted_decision_tables
    decision_tables.sort_by { |d| [d.start_period, d.name].map(&:to_s).join("-") }
  end

  def used_formulas(formula)
    rule_type.used_formulas(formula)
  end

  def used_by_formulas(formula)
    rule_type.used_by_formulas(formula)
  end

  def refactor(formula, new_code)    
    rule_type.refactor(formula, new_code)
  end

  def parent_id
    kind == RULE_TYPE_PAYMENT ? payment_rule_id : package_id
  end

  def activity_kind?
    kind == RULE_TYPE_ACTIVITY
  end

  def activity_related_kind?
    activity_kind? || zone_activity_kind?
  end

  def package_kind?
    kind == RULE_TYPE_PACKAGE
  end

  def payment_kind?
    kind == RULE_TYPE_PAYMENT
  end

  def multi_entities_kind?
    kind == RULE_TYPE_MULTI_ENTITIES
  end

  def zone_kind?
    kind == RULE_TYPE_ZONE
  end

  def zone_activity_kind?
    kind == RULE_TYPE_ZONE_ACTIVITY
  end

  def zone_related_kind?
    zone_kind? || zone_activity_kind?
  end

  def rule_type
    @rule_type ||= RuleTypes.from_rule(self)
  end

  def kind=(new_kind)
    @rule_type = nil
    super
  end

  def code
    @code = Orbf::RulesEngine::Codifier.codify(name)
  end

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts
  end

  def formula_codes
    formulas.map(&:code)
  end

  def formulas_are_coherent
    @solver ||= Rules::Solver.new
    @solver.validate_formulas(self) if name
  end

  def formula(code)
    formulas.find { |f| f.code == code }
  end

  # see PaperTrailed
  delegate :project_id, to: :project
  delegate :program_id, to: :project

  def project
    rule_type.project
  end

  def package_formula_uniqness
    rule_type.package_formula_uniqness
  end

  def available_variables
    rule_type.available_variables
  end

  def used_available_variables
    used_variables_for_values
  end

  def used_variables_for_values
    formulas.map(&:values_dependencies).flatten
  end

  def dependencies
    formulas.map(&:dependencies).uniq.flatten
  end

  def available_variables_for_values
    rule_type.available_variables_for_values
  end

  def fake_facts
    rule_type.fake_facts
  end

  def to_unified_h
    { stable_id: stable_id,
      name:      name,
      kind:      kind,
      formulas:  Hash[formulas.map do |formula|
        [formula.code, { description: formula.description, expression: formula.expression }]
      end] }
  end

  def to_s
    "Rule##{id}-#{kind}-#{name}"
  end
end
