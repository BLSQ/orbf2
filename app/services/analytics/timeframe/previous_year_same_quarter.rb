module Analytics
  module Timeframe
    class PreviousYearSameQuarter < PreviousYear
      def suffix
        "_previous_year_same_quarter_values"
      end

      def periods(_package, year_month)
        start_period = year_month.minus_years(1)
        periods = [
          start_period.to_quarter.months,
          start_period.to_quarter
        ]
        periods.flatten.uniq
      end
    end
  end
end
