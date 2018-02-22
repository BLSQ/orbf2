# frozen_string_literal: true

# == Schema Information
#
# Table name: rules
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  kind            :string           not null
#  package_id      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  payment_rule_id :integer
#  stable_id       :uuid             not null
#

class Rule < ApplicationRecord
  include PaperTrailed
  RULE_TYPE_MULTI_ENTITIES = "multi-entities"
  RULE_TYPE_ACTIVITY = "activity"
  RULE_TYPE_PACKAGE = "package"
  RULE_TYPE_PAYMENT = "payment"

  RULE_TYPES = [
    RULE_TYPE_PAYMENT, RULE_TYPE_ACTIVITY,
    RULE_TYPE_PACKAGE, RULE_TYPE_MULTI_ENTITIES
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

  def activity_kind?
    kind == RULE_TYPE_ACTIVITY
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

  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts
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
    if activity_kind? || package_kind? || multi_entities_kind?
      package.project
    elsif payment_kind?
      payment_rule.project
    end
  end

  def package_formula_uniqness
    formula_by_codes = formulas.group_by(&:code)
    if package_kind? && package.project
      all_package_formulas = package.project.packages.flat_map(&:rules).select(&:package_kind?).flat_map(&:formulas)
      all_formulas_by_codes = all_package_formulas.group_by(&:code)
      all_formulas_by_codes.each do |code, non_uniq_formulas|
        next unless formula_by_codes[code]
        if non_uniq_formulas.size > 1
          errors[:formulas] << "Formula's code must be unique accross packages, you have #{non_uniq_formulas.size} formulas with '#{code}' in #{non_uniq_formulas.map(&:rule).map(&:package).map(&:name).join(' and ')}"
        end
      end
    end

    formula_by_codes.each do |code, formulas|
      errors[:formulas] << "Formula's code must be unique, you have #{formulas.size} formulas with '#{code}'" if formulas.size > 1
    end
  end

  def available_variables
    var_names = []
    if activity_kind?
      var_names << package.states.select(&:activity_level?).map(&:code) if package
      var_names << formulas.map(&:code)
      var_names << Analytics::Locations::LevelScope.new.facts(package)
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }
      var_names << "quarter_of_year"
      var_names << "month_of_year"
      if package.multi_entities?
        var_names << "org_units_sum_if_count" if package.multi_entities_rule
        var_names << "org_units_count"
      end
    elsif package_kind?
      var_names << package.states.select(&:package_level?).map(&:code) if package
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }
    elsif payment_kind?
      rules = payment_rule.packages.flat_map(&:rules).select(&:package_kind?)
      var_names << rules.flat_map(&:formulas).map(&:code)
      var_names << available_variables_for_values.map { |code| "%{#{code}}" }
    elsif multi_entities_kind?
      var_names << package.states.select(&:activity_level?).map(&:code)
    end
    var_names << decision_tables.map(&:out_headers) if decision_tables.any?
    var_names.flatten.uniq.reject(&:nil?).sort
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
    var_names = []
    if activity_kind?
      activity_level_states = package.package_states.map(&:state).select(&:activity_level?)
      Analytics::Timeframe.all_variables_builders.each do |timeframe|
        var_names << activity_level_states.map { |state| "#{state.code}#{timeframe.suffix}" }
      end
    end
    if package_kind? && package.activity_rule
      var_names << package.activity_rule.formulas.map(&:code).map { |code| "#{code}_values" }
    end
    if payment_kind? && payment_rule.monthly?
      var_names << payment_rule.packages
                               .flat_map(&:package_rule)
                               .map(&:formulas)
                               .flatten
                               .map(&:code)
                               .map { |code| "#{code}_values" }
      var_names << payment_rule.rule.formulas.map(&:code).map { |code| "#{code}_previous_values" }
    end

    var_names.flatten
  end

  def fake_facts
    if activity_kind?
      # in case we are in a clone packages a not there so go through long road package_states instead of states
      facts = to_fake_facts(package.package_states.map(&:state).select(&:activity_level?))
              .merge(
                Analytics::Locations::LevelScope.new.to_fake_facts(package)
              )
              .merge("org_units_count" => "1", "org_units_sum_if_count" => "1")
      facts
    elsif package_kind?
      # in case we are in a clone packages a not there so go through long road package_states instead of states
      to_fake_facts(package.package_states.map(&:state).select(&:package_level?))
    elsif multi_entities_kind?
      to_fake_facts(package.package_states.map(&:state).select(&:activity_level?))
    elsif payment_kind?
      facts = {}
      packages = payment_rule.packages
      # in case we are in a clone packages a not there so go through long road
      packages = payment_rule.package_payment_rules.flat_map(&:package) if packages.empty?
      rules = packages.flat_map(&:rules).select(&:package_kind?)
      rules.flat_map(&:formulas).each do |formula|
        facts[formula.code] = "1040.1"
      end
      facts
    end
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

  def extra_facts(activity, entity_facts)
    return {} if decision_tables.empty?
    entity_and_activity_facts = entity_facts.merge(activity_code: activity.code)
    extra_facts = decision_tables.map { |decision_table| decision_table.extra_facts(entity_and_activity_facts) }.compact
    extra_facts ||= [{}]
    final_facts = extra_facts.reduce({}, :merge)
    raise "#{name} : no value found for #{entity_and_activity_facts} in decision table #{decision_tables.map(&:decision_table).map(&:to_s).join("\n")}" if final_facts.empty?
    final_facts
  end

  private

  def to_fake_facts(states)
    facts = states.map { |state| [state.code.to_sym, "10"] }.to_h
    facts[:quarter_of_year] = 3
    org_unit_facts = decision_tables.flat_map(&:out_headers).map { |header| [header.to_sym, "10"] }.to_h
    facts.merge org_unit_facts
  end
end
