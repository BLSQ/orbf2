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
      puts "activity_and_values(#{package.name}, #{date}) => #{@org_units_by_package[package].size} #{@org_units_by_package[package].map(&:name)}"

      org_unit_ids = @org_units_by_package[package].map(&:id)

      values = package.activities.map do |activity|
        facts = activity.activity_states.select(&:external_reference?).map do |activity_state|
          formatted_period = "#{date.year}#{date.month.to_s.rjust(2, '0')}"
          activity_values = @values_by_data_element_and_period[[activity_state.external_reference, formatted_period]] || []
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

        [activity, Values.new(date, facts)]
      end

      values
    end


    def aggregation(activity_values, activity_state)
      aggregation_type = @aggregation_per_data_elements[activity_state.external_reference] || "SUM"
      values_for_activity = activity_values.map { |v| v["value"] }.map(&:to_f)
      puts "#{activity_state.external_reference} : activity_values #{activity_values.size}"

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