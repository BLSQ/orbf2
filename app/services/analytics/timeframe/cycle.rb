module Analytics
  module Timeframe
    class Cycle
      def suffix
        "_current_cycle_values"
      end

      def periods(package, year_month)
        if package.frequency == "yearly"
          []
        elsif package.frequency == "monthly"
          year_months = if package.project.cycle_yearly?
                          year_month.to_year.months
                        else
                          year_month.to_quarter.months
                        end
          year_months.select { |period| period < year_month }
        else
          year_quarter = year_month.to_quarter
          year_quarters = package.project.cycle_yearly? ? year_month.to_year.quarters : []
          year_quarters.select { |period| period < year_quarter }
        end
      end

      def build_variables(package, activity, year_month, org_unit_ids, service)
        previous_facts = periods(package, year_month).map do |period|
          service.facts_for_period(package, activity, [period], org_unit_ids)
        end

        activities_states = activity.activity_states.select(&:external_reference?)
        activities_states.map do |activity_state|
          [
            activity_state.state.code.to_s + suffix,
            previous_facts.map { |fact| fact[activity_state.state.code] || 0 }
          ]
        end.to_h
      end
    end
  end
end
