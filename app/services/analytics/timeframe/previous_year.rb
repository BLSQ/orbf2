module Analytics
  module Timeframe
    class PreviousYear
      def suffix
        "_previous_year_values"
      end

      def periods(package, year_month)
        periods = []
        if package.activity_rule
          previous_year = year_month.minus_years(1).to_year
          periods << previous_year.months.map { |ym| Timeframe.enumerate_periods(package, ym) }
        end
        periods.flatten.uniq
      end

      def build_variables(package, activity, year_month, org_unit_ids, service)
        variables = {}

        previous_facts = periods(package, year_month).map do |period|
          [period, service.facts_for_period(package, activity, [period], org_unit_ids)]
        end.to_h

        activity.activity_states.map do |activity_state|
          vals = previous_facts.values.compact.map { |fact| fact[activity_state.state.code] }.compact
          vals = [0] if vals.empty?
          variables[activity_state.state.code.to_s + suffix] = vals
        end

        activity.activity_states.each do |activity_state|
          variables[activity_state.state.code.to_s + suffix] ||= [0]
        end

        package.states.each do |state|
          variables["#{state.code}#{suffix}"] ||= [0]
        end

        variables
      end
    end
  end
end
