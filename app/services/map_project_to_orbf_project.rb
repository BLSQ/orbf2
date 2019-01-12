# frozen_string_literal: true

require "orbf/rules_engine"

class MapProjectToOrbfProject
  def initialize(project, dhis2_indicators, engine_version = nil)
    @project = project
    @dhis2_indicators_by_id = dhis2_indicators.index_by(&:id)
    @engine_version = engine_version || project.engine_version
  end

  def map
    Orbf::RulesEngine::Project.new(
      packages:                              map_packages(project.packages),
      payment_rules:                         map_payment_rules,
      dhis2_params:                          project.dhis_configuration,
      engine_version:                        @engine_version,
      default_category_combo_ext_id:         project.default_coc_reference,
      default_attribute_option_combo_ext_id: project.default_aoc_reference
    )
  end

  private

  attr_reader :project, :packages, :dhis2_indicators_by_id

  PACKAGE_KINDS = {
    "multi-groupset" => "subcontract"
  }.freeze

  def map_packages(packages)
    packages.map do |package|
      map_package(package)
    end
  end

  def map_package(package)
    @cache_package ||= {}
    from_cache = @cache_package[package]
    return from_cache if from_cache

    @cache_package[package] = Orbf::RulesEngine::Package.new(
      code:                          package.code,
      kind:                          PACKAGE_KINDS[package.kind] || package.kind,
      frequency:                     package.frequency,
      main_org_unit_group_ext_ids:   package.main_entity_groups
                                        .map(&:organisation_unit_group_ext_ref).compact,

      target_org_unit_group_ext_ids: package.target_entity_groups
                                      .map(&:organisation_unit_group_ext_ref).compact,
      groupset_ext_id:               package.ogs_reference,
      matching_groupset_ext_ids:     package.groupsets_ext_refs,
      dataset_ext_ids:               package.package_states.map(&:ds_external_reference).compact,
      activities:                    map_activities(package.activities, package.states),
      rules:                         map_rules(package.rules)
    )
  end

  def map_activities(package_activities, package_states)
    package_activities.map do |activity|
      Orbf::RulesEngine::Activity.with(
        name:            activity.name,
        activity_code:   activity.code,
        activity_states: map_activity_states(activity.activity_states, package_states)
      )
    end
  end

  ACTIVITY_STATE_KIND = {
    "formula" => "constant"
  }.freeze

  def map_activity_states(activity_states, package_states)
    activity_states.select { |activity_state| package_states.include?(activity_state.state) }
                   .map do |activity_state|
      kind = ACTIVITY_STATE_KIND[activity_state.kind] || activity_state.kind
      formula = activity_state.formula ||
                dhis2_indicators_by_id[activity_state.external_reference]&.numerator
      ext_id = activity_state.external_reference
      if activity_state.kind_data_element_coc?
        # fake date_element_coc as indicator
        kind = "indicator"
        formula = '#{' + activity_state.external_reference + "}"
        ext_id = "inlined-" + ext_id
      end
      Orbf::RulesEngine::ActivityState.with(
        state:   activity_state.state.code,
        name:    activity_state.name,
        formula: formula,
        kind:    kind,
        ext_id:  ext_id
      )
    end
  end

  RULE_KINDS = { "multi-entities" => "entities_aggregation" }.freeze

  def map_rules(rules)
    rules.map do |rule|
      map_rule(rule)
    end
  end

  def map_rule(rule)
    Orbf::RulesEngine::Rule.new(
      kind:            RULE_KINDS[rule.kind] || rule.kind,
      formulas:        map_formulas(rule.formulas),
      decision_tables: map_decision_tables(rule.decision_tables)
    )
  end

  def map_formulas(formulas)
    formulas.map do |formula|
      Orbf::RulesEngine::Formula.new(
        formula.code,
        formula.expression,
        formula.description,
        map_formula_mappings(formula)
      )
    end
  end

  def map_formula_mappings(formula)
    formula_mappings = {}
    formula_mappings[:frequency] = formula.frequency if formula.frequency
    formula_mappings[:exportable_formula_code] = formula.exportable_formula_code if formula.exportable_formula_code
    if formula.rule.activity_kind? && formula.formula_mappings.any?
      formula_mappings[:activity_mappings] = formula.formula_mappings
                                                    .each_with_object({}) do |mapping, hash|
        hash[mapping.activity.code] = mapping.external_reference
      end
    elsif !formula.rule.activity_kind? && formula.formula_mappings.size == 1
      formula_mappings[:single_mapping] = formula.formula_mappings.first.external_reference
    end
    formula_mappings
  end

  def map_decision_tables(decision_tables)
    decision_tables.map do |decision_table|
      Orbf::RulesEngine::DecisionTable.new(decision_table.content)
    end
  end

  def map_payment_rules
    project.payment_rules.map do |payment_rule|
      Orbf::RulesEngine::PaymentRule.new(
        code:      payment_rule.code,
        frequency: payment_rule.frequency,
        packages:  map_packages(payment_rule.packages),
        rule:      map_rule(payment_rule.rule)
      )
    end
  end
end
