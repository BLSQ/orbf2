module Analytics
  class CachedAnalyticsService
    def initialize(org_units, values)
      @values = values
      @org_units = org_units
    end

    def entities
    end

    def activity_and_values(package, date)
      package.activities.map do |activity|
        puts "#{activity.name}"
        facts = Hash[activity.activity_states.map do |activity_state|
          values_for_activity = @values.select {|value| value["data_element"]== activity_state.external_reference }
                                .select {|value| value["period"]== "#{date.year}#{date.month.to_s.rjust(2,"0")}" }
                                .map {|v| v["value"]}
                                .map(&:to_f)
          puts "\t#{activity_state.state.code}=>#{ values_for_activity.sum}"
          [activity_state.state.code, values_for_activity.sum]
        end]

        package.states.each do |state|
          facts[state.code] ||= 0
        end

        [ activity, Values.new(date,facts)]
      end
    end
  end
end
