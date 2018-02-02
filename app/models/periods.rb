module Periods
  def self.from_dhis2_period(period)
    raise ArgumentError, "period can't be nil" unless period
    return Year.new(period) if period.length == 4
    return YearQuarter.new(period) if period.include?("Q")
    YearMonth.new(period[0..3], period[4..5])
  end

  def self.year_month(date)
    YearMonth.new(date.year, date.month)
  end
end
