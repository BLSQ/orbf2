module Analytics
  class CachedAnalyticsService
    def initialize(org_units, org_units_by_package, values, aggregation_per_data_elements)
      @values = values
      @org_units = org_units
      @org_units_by_package = org_units_by_package
      @values_by_data_element_and_period = @values.group_by { |value| [value["data_element"], value["period"]] }
      @aggregation_per_data_elements = aggregation_per_data_elements
    end

    def entities; end

    def activity_and_values(package, date)
      year_month = Periods.year_month(date)
      org_unit_ids = @org_units_by_package[package].map(&:id)

      values = package.activities.map do |activity|
        facts = activity.activity_states.select(&:external_reference?).map do |activity_state|
          activity_values = []
          formatted_periods(date, package).map do |formatted_period|
            activity_values += @values_by_data_element_and_period[[activity_state.external_reference, formatted_period]] || []
          end

          activity_values = activity_values.select { |v| org_unit_ids.include?(v.org_unit) }

          [activity_state.state.code, aggregation(activity_values, activity_state)]
        end.to_h

        activity.activity_states.select(&:kind_formula?).each do |activity_state|
          facts[activity_state.state.code] = activity_state.formula
        end

        package.states.each do |state|
          # puts " !!!\t#{activity.name}\twarn defaulting to 0\t#{state.code}" unless facts[state.code]
          facts[state.code] ||= 0
        end

        variables = activity.activity_states.select(&:external_reference?).map do |activity_state|
          previous_activity_values = []
          previous_periods(year_month, package).map do |period|
            previous_activity_values += @values_by_data_element_and_period[[activity_state.external_reference, period.to_dhis2]]|| []
          end
          previous_activity_values = previous_activity_values.select { |v| org_unit_ids.include?(v.org_unit) }.map(&:value)

          previous_activity_values = [0] if previous_activity_values.empty?
          ["#{activity_state.state.code}_previous_values", previous_activity_values]
        end.to_h

        [activity, Values.new(date, facts, variables)]
      end

      values
    end

    def previous_periods(year_month, package)
      year_months = package.project.cycle_yearly? ? year_month.to_year.months : year_month.to_quarter.months
      year_months.select { |period| period < year_month }
    end

    def formatted_periods(date, package)
      year_month = Periods.year_month(date)
      if package.frequency == "monthly"
        [year_month.to_dhis2]
      else
        [year_month, year_month.to_quarter].map(&:to_dhis2)
      end
    end

    def aggregation(activity_values, activity_state)
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
  end
end
