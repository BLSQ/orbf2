module Analytics
  class CachedAnalyticsService
    def initialize(org_units, values)
      @values = values
      @org_units = org_units
      @values_by_data_element_and_period = @values.group_by {|value| [value["data_element"],value["period"]]}
    end

    def entities; end

    def activity_and_values(package, date)
      package.activities.map do |activity|
        facts = Hash[activity.activity_states.select(&:kind_data_element?).map do |activity_state|
          activity_values = @values_by_data_element_and_period[[activity_state.external_reference,"#{date.year}#{date.month.to_s.rjust(2, '0')}"  ]] || []
          values_for_activity =  activity_values.map { |v| v["value"] }.map(&:to_f)
          [activity_state.state.code, values_for_activity.sum]
        end]

        activity.activity_states.select(&:kind_formula?).each do |activity_state|
          facts[activity_state.state.code] = activity_state.formula
        end

        package.states.each do |state|
          #puts " !!!\t#{activity.name}\twarn defaulting to 0\t#{state.code}" unless facts[state.code]
          facts[state.code] ||= 0
        end

        [activity, Values.new(date, facts)]
      end
    end
  end
end
