module Analytics
  class Timeframe
    def self.current
      @current ||= Current.new
    end

    def self.previous_year
      @previous_year ||= PreviousYear.new
    end

    def self.previous_year_same_quarter
      @previous_year_same_quarter ||= PreviousYearSameQuarter.new
    end

    def self.all_variables_builders
      [cycle, previous_year, previous_year_same_quarter]
    end

    def self.cycle
      @cycle ||= Cycle.new
    end

    def enumerate_periods(package, year_month)
      periods = []
      if package.frequency == "monthly"
        periods << [year_month, year_month.to_year]
      elsif package.frequency == "quarterly"
        quarter = year_month.to_quarter
        periods << [quarter, quarter.months, year_month.to_year]
      end
      if package.frequency == "yearly" || package.project.cycle_yearly?
        year = year_month.to_year
        periods << [year.months, year.quarters, year]
      end

      periods.flatten.uniq
    end

    class Current
      def suffix
        nil
      end

      def periods(package, year_month)
        if package.frequency == "monthly"
          [year_month, year_month.to_year]
        elsif package.frequency == "quarterly"
          [year_month, year_month.to_quarter, year_month.to_year]
        elsif package.frequency == "yearly" || package.project.cycle_yearly?
          [year_month.to_year]
        end
      end
    end

    class Cycle
      def suffix
        "_current_cycle_values"
      end

      def periods(package, year_month)
        if package.frequency == "yearly"
          []
        elsif package.frequency == "monthly"
          year_months = project.cycle_yearly? ? year_month.to_year.months : year_month.to_quarter.months
          year_months.select { |period| period < year_month }
        else
          year_quarter = year_month.to_quarter
          year_quarters = project.cycle_yearly? ? year_month.to_year.quarters : []
          year_quarters.select { |period| period < year_quarter }
        end
      end

      def build_variables(package, activity, year_month, org_unit_ids, service)
        previous_facts = periods(package, year_month).map do |period|
          service.facts_for_period(activity, [period], org_unit_ids)
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

    class PreviousYear
      def suffix
        "_previous_year_values"
      end

      def periods(_package, year_month)
        periods = []
        if activity_rule && activity_rule.use_previous_year_values?
          previous_year = year_month.minus_years(1).to_year
          periods << previous_year.months.map { |yq| periods(yq, false) }
        end
        periods.flatten.uniq
      end

      def build_variables(package, activity, year_month, org_unit_ids, service)
        variables = {}

        previous_facts = periods(package, year_month).map do |period|
          [period, service.facts_for_period(activity, [period], org_unit_ids)]
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

    class PreviousYearSameQuarter < PreviousYear
      def suffix
        "_previous_year_same_quarter_values"
      end

      def periods(package, year_month)
        package.previous_year_same_quarter_periods(year_month)
      end
    end
  end
end
