module Analytics
  module Timeframe
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
  end
end
