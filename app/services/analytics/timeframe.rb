module Analytics
  module Timeframe
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

    def self.all
      [current, cycle, previous_year, previous_year_same_quarter]
    end

    def self.cycle
      @cycle ||= Cycle.new
    end

    def self.enumerate_periods(package, year_month)
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
  end
end
