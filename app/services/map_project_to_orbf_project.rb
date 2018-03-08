class MapProjectToOrbfProject
  def initialize(project)
    @project = project
  end

  def map
    Orbf::RulesEngine::Project.new(
      packages:      map_packages,
      payment_rules: map_payment_rules,
      dhis2_params:  project.dhis_configuration.client_params
    )
  end

  private

  attr_reader :project, :packages

  PACKAGE_KINDS = {
    "single"         => "single",
    "multi-groupset" => "subcontract"
  }.freeze

  def map_packages
    @packages = project.packages.map do |package|
      Orbf::RulesEngine::Package.new(
        code:                   Codifier.codify(package.name),
        kind:                   PACKAGE_KINDS[package.kind],
        frequency:              package.frequency,
        org_unit_group_ext_ids: package.package_entity_groups.map(&:organisation_unit_group_ext_ref).compact,
        groupset_ext_id:        package.ogs_reference,
        dataset_ext_ids:        package.package_states.map(&:ds_external_reference).compact,
        activities:             map_activities(package.activities),
        rules:                  map_rules(package.rules)
      )
    end
  end

  def map_activities(package_activities)
    package_activities.map do |activity|
      Orbf::RulesEngine::Activity.with(
        activity_code:   activity.code,
        activity_states: map_activity_states(activity.activity_states)
      )
    end
  end

  def map_activity_states(activity_states)
    activity_states.map do |activity_state|
      Orbf::RulesEngine::ActivityState.with(
        state:   activity_state.state.code,
        name:    activity_state.name,
        formula: activity_state.formula,
        kind:    activity_state.kind,
        ext_id:  activity_state.external_reference
      )
    end
  end

  def map_rules(rules)
    rules.map do |rule|
      Orbf::RulesEngine::Rule.new(
        kind:            rule.kind,
        formulas:        map_formulas(rule.formulas),
        decision_tables: map_decision_tables(rule.decision_tables)
      )
    end
  end

  def map_formulas(formulas)
    formulas.map do |formula|
      Orbf::RulesEngine::Formula.new(
        formula.code,
        formula.expression,
        formula.description
      )
    end
  end

  def map_decision_tables(decision_tables)
    decision_tables.map do |decision_table|
      Orbf::RulesEngine::DecisionTable.new(decision_table.content)
    end
  end

  def map_payment_rules
    # TODO: implement
    []
  end
end
