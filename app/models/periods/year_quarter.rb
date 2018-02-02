module Periods
  class YearQuarter
    include Comparable

    QUARTER_TO_END_MONTH = {
      1 => 3,
      2 => 6,
      3 => 9,
      4 => 12
    }.freeze

    attr_reader :yyyyqq, :quarter, :year, :months

    def initialize(yyyyqq)
      raise ArgumentError, "Argument yyyyqq can't be nil" unless yyyyqq
      @yyyyqq = yyyyqq.freeze
      components = yyyyqq.split("Q")
      @quarter = Integer(components.last)
      @year = Integer(components.first)
      raise "no a valid quarter number for '#{yyyyqq}'" if quarter <= 0 || quarter > 4
    end

    def <=>(other)
      yyyyqq <=> other.yyyyqq
    end

    def equal?(other)
      self.class == other.class && yyyyqq == other.yyyyqq
    end

    alias eql? equal?

    def hash
      @yyyyqq.hash
    end

    def to_s
      @yyyyqq
    end

    def to_year
      @year_value ||= Year.new(@year.to_s)
    end

    def start_date
      @start_date ||= Date.parse("#{year}-#{(QUARTER_TO_END_MONTH[quarter.to_i] - 2)}-01")
    end

    def end_date
      @end_date ||= start_date.end_of_quarter
    end

    def months
      @months ||= ((quarter * 3 - 2)..(quarter * 3))
                  .map { |month| YearMonth.new(@year, month) }
                  .freeze
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

    def to_quarter
      self
    end

    def inspect
      self.class.name + "-" + to_dhis2
    end
  end
end
