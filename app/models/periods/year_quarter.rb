module Periods
  class YearQuarter
    include Comparable
    attr_reader :yyyyqq, :quarter, :year, :months

    def initialize(yyyyqq)
      @yyyyqq = yyyyqq.freeze
      components = yyyyqq.split("Q")
      @quarter = components.last.to_i
      @year = components.first.to_i
      raise "no a valid quarter number for '#{yyyyqq}'" if quarter <= 0 || quarter > 4
      @months = ((quarter * 3 - 2)..(quarter * 3)).map { |month| YearMonth.new(@year, month) }.freeze
    end

    def <=>(other_quarter)
      yyyyqq <=> other_quarter.yyyyqq
    end

    def ==(other_quarter)
      self.class == other_quarter.class && yyyyqq == other_quarter.yyyyqq
    end

    alias eql? ==

    def hash
      @yyyyqq.hash
    end

    def to_s
      @yyyyqq
    end

    def to_year
      @year_value ||= Year.new(@year.to_s)
    end

    QUARTER_TO_END_MONTH = {
      1 => 3,
      2 => 6,
      3 => 9,
      4 => 12
    }.freeze

    def start_date
      @start_date ||= Date.parse("#{year}-#{(QUARTER_TO_END_MONTH[quarter.to_i] - 2)}-01")
    end

    def end_date
      @end_date ||= Date.parse("#{year}-#{QUARTER_TO_END_MONTH[quarter.to_i]}-01").end_of_month
    end

    def to_dhis2
      yyyyqq
    end

    def self.from_yyyyqq(yyyyqq)
      YearQuarter.new(yyyyqq)
    end

    def self.from_year_month(year, month)
      YearQuarter.new("#{year}Q#{(month / 3.0).ceil}")
    end

    def inspect
      self.class.name + "-" + to_dhis2
    end
  end
end
