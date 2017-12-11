module Analytics
  class CachedAnalyticsService
    def initialize(org_units, org_units_by_package, values, aggregation_per_data_elements)
      @values = values
      @org_units = org_units
      @org_units_by_package = org_units_by_package
      @values_by_data_element_and_period = @values.group_by { |value| [value["data_element"], value["period"]] }
      @aggregation_per_data_elements = aggregation_per_data_elements
      @entity_builder = Invoicing::EntityBuilder.new
    end

    def entities; end

    def activity_and_values(package, date)
      year_month = Periods.year_month(date)
      org_unit_ids = @org_units_by_package[package].map(&:id).to_set
      values = package.activities.map do |activity|
        [
          activity,
          Values.new(
            date,
            build_facts(package, activity, year_month, org_unit_ids),
            build_variables(package, activity, year_month, org_unit_ids)
          )
        ]
      end
      values
    end

    def build_facts(package, activity, year_month, org_unit_ids)
      facts = facts_for_period(
        package,
        activity,
        Timeframe.current.periods(package, year_month),
        org_unit_ids
      )

      activity.activity_states.select(&:kind_formula?).each do |activity_state|
        facts[activity_state.state.code] = activity_state.formula
      end

      package.states.each do |state|
        facts[state.code] ||= 0
      end

      facts = facts.merge(
        Analytics::Locations::LevelScope.new.facts_values(
          @org_units_by_package[package],
          package,
          activity,
          year_month,
          self
        )
      )
    end

    def build_variables(package, activity, year_month, org_unit_ids)
      variables = {}

      Timeframe.all_variables_builders.each do |timeframe|
        variables = variables.merge(
          timeframe.build_variables(
            package,
            activity,
            year_month,
            org_unit_ids,
            self
          )
        )
      end
      variables
    end

    def org_units_count_facts(package, activity, org_unit_ids)
      org_units_count = org_unit_ids.size
      if package.multi_entities_rule && org_unit_ids.size > 1
        org_units_count = org_unit_ids.count { |org_unit_id| sum_if?(package, activity, org_unit_id) }
      end

      {
        org_units_sum_if_count: org_units_count,
        org_units_count:        org_unit_ids.size
      }
    end

    def facts_for_period(package, activity, periods, org_unit_ids)
      @org_unit_facts_by_org_id ||= {}

      states_values = activity.activity_states.select(&:external_reference?).map do |activity_state|
        activity_values = []
        periods.map do |formatted_period|
          activity_values += @values_by_data_element_and_period[
            [activity_state.external_reference, formatted_period.to_dhis2]
          ] || []
        end
        activity_values = activity_values.select { |v| org_unit_ids.include?(v.org_unit) }
        if package.multi_entities_rule && org_unit_ids.size > 1
          activity_values = activity_values.select do |v|
            sum_if?(package, activity, v.org_unit)
          end
        end
        [activity_state.state.code, aggregation(activity_values, activity_state)]
      end

      states_values.to_h.merge(org_units_count_facts(package, activity, org_unit_ids))
    end

    def sum_if?(package, activity, org_unit_id)
      @org_unit_facts_by_org_id[[package.id, activity.id, org_unit_id]] ||= @entity_builder.to_entity(
        @org_units_by_package[package].find { |org_unit| org_unit.id == org_unit_id }
      ).facts
      facts = package.multi_entities_rule.extra_facts(activity, @org_unit_facts_by_org_id[[package.id, activity.id, org_unit_id]])
      log_debug(" #{package.name} / #{activity.name} - #{activity.code} > #{facts} : #{@org_unit_facts_by_org_id[[package.id, activity.id, org_unit_id]]}")

      facts["sum_if"] == "true"
    end

    def aggregation(activity_values, activity_state)
      log_debug("aggregating : #{activity_values}") if activity_values.size > 1
      aggregation_type = @aggregation_per_data_elements[activity_state.external_reference] || "SUM"
      values_for_activity = activity_values.map { |v| v["value"] }.map(&:to_f)

      case aggregation_type
      when "MIN"
        values_for_activity.min
      when "MAX"
        values_for_activity.max
      when "SUM"
        values_for_activity.sum
      when "AVERAGE"
        values_for_activity.empty? ? 0 : values_for_activity.sum / values_for_activity.size
      else
        raise "aggregation_type #{aggregation_type} not supported"
      end
    end

    def log_debug(message)
      puts message if ENV["DEBUG"]
    end
  end
end
