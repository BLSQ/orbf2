# frozen_string_literal: true

module Analytics
  module Timeframe
    class PreviousYearSameQuarter < PreviousYear
      def suffix
        "_previous_year_same_quarter_values"
      end
    end
  end
end
