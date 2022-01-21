# frozen_string_literal: true

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

  YEARLY = "yearly"
  MONTHLY = "monthly"
  QUARTERLY = "quarterly"
  SIX_MONTHLY = "sixMonthly"
  FINANCIAL_JULY = "financialJuly"

  def self.detect(dhis2Period)
    return QUARTERLY if dhis2Period[4] == "Q" && dhis2Period.size == 6

    return SIX_MONTHLY if dhis2Period.include?("S")

    return MONTHLY if dhis2Period.size == 6

    return YEARLY if dhis2Period.size == 4

    return FINANCIAL_JULY if dhis2Period.include?("July")

    raise "Unsupported period format : '#{dhis2Period}'"
  end
end
