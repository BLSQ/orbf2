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
  end
end
