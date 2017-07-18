require "rails_helper"

describe Periods do
  it "should parse yyyy" do
    expect(Periods.from_dhis2_period("2016")).to eq Periods::Year.new(2016)
  end

  it "should parse yyyyQq" do
    expect(Periods.from_dhis2_period("2016Q1")).to eq Periods::YearQuarter.new("2016Q1")
  end

  it "should parse yyyymm" do
    expect(Periods.from_dhis2_period("201610")).to eq Periods::YearMonth.new("2016", 10)
  end
end
