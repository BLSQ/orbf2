module Periods
  class YearMonth
    include Comparable
    attr_reader :year, :month

    def initialize(year, month)
      @year = Integer(year)
      month = month[1..-1] if month && month.is_a?(String) && month.start_with?("0")
      @month = Integer(month)
      raise "no a valid month number for '#{month}'" if @month < 1 || @month > 12
    end

    def <=>(other)
      to_dhis2 <=> other.to_dhis2
    end

    def equal?(other)
      self.class == other.class && self == other
    end

    alias eql? equal?

    delegate :hash, to: :to_dhis2

    def name
      Date::MONTHNAMES[month]
    end

    def minus_years(years)
      YearMonth.new(year - years, month)
    end

    def month_of_quarter
      to_quarter.months.index(self) + 1
    end

    def start_date
      @start_date ||= Date.parse("#{year}-#{@month}-01")
    end

    def end_date
      @end_date ||= start_date.end_of_month
    end

    def to_quarter
      @quarter ||= YearQuarter.from_year_month(year, month)
    end

    def to_year
      @year_value ||= Year.new(@year.to_s)
    end

    def to_dhis2
      @dhis2 ||= "#{@year}#{@month.to_s.rjust(2, '0')}"
    end

    alias to_s to_dhis2

    def inspect
      self.class.name + "-" + to_dhis2
    end
  end
end
