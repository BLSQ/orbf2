class LevelScope
  def facts(package)
    variable_states(package).keys
  end

  def to_fake_facts(package)
    facts(package).map { |code| [code.to_sym, "10"] }.to_h
  end

  def facts_values(_current_facts,
                   org_units,
                   package,
                   activity,
                   year_month,
                   service)

    level_dependencies = package.activity_rule.dependencies & facts(package)
    vars = variable_states(package)
    values = {}
    level_dependencies.each do |state_level|
      level = state_level.last.to_i
      state = vars[state_level]
      level_org_ids = org_units.map { |org_unit| org_unit.path.split("").reject(&:empty?) }.map { |path| path[level] }.flatten.uniq
      values_for_period = service.facts_for_period(activity, [year_month], [level_org_ids.first])
      values[state_level] = values_for_period[state.code]
    end
    puts "LevelScope : #{level_dependencies} =>  #{values}"

    values
  end

  private

  def variable_states(package)
    states = package.states.select(&:activity_level?)
    (1..5).flat_map do |level|
      states.map { |state| ["#{state.code}_level_#{level}", state] }
    end.to_h
  end
end
