# frozen_string_literal: true

require "rails_helper"

describe Periods::YearMonth do
  let(:yyyymm) { "201603" }
  let(:yyyymm_minus1) { "201602" }
  let(:year_month) { Periods.from_dhis2_period(yyyymm) }
  let(:year_month_minus1) { Periods.from_dhis2_period(yyyymm_minus1) }
  it "should have to_dhis2" do
    expect(year_month.to_dhis2).to eq "201603"
  end

  describe "fails fast" do
    it "when year is nil" do
      expect { Periods::YearMonth.new(nil, 1) }.to raise_error(TypeError, "can't convert nil into Integer")
    end
    it "when month is nil" do
      expect { Periods::YearMonth.new(2016, nil) }.to raise_error(TypeError, "can't convert nil into Integer")
    end
    it "when year is a alpha" do
      expect { Periods::YearMonth.new("year", 1) }.to raise_error('invalid value for Integer(): "year"')
    end
    it "when month is a alpha" do
      expect { Periods::YearMonth.new("2016", "month") }.to raise_error('invalid value for Integer(): "month"')
    end
  end
  it "can use it as uniqueness" do
    periods = [
      Periods.from_dhis2_period(yyyymm),
      Periods.from_dhis2_period(yyyymm)
    ]
    expect(periods.uniq.size).to eq 1
  end

  it "has start and end date" do
    expect(year_month.start_date.to_s).to eq("2016-03-01")
    expect(year_month.end_date.to_s).to eq("2016-03-31")
  end

  it "should be comparable" do
    expect(year_month_minus1 < year_month).to eq true
    expect(year_month < year_month).to eq false
  end

  it "should have non verbose inspect" do
    expect(year_month.inspect).to eq "Periods::YearMonth-201603"
  end

  it "should allow to navigate to corresponding Periods::Year" do
    expect(year_month.to_year.months).to include(year_month)
    expect(year_month.to_year).to eq(Periods.from_dhis2_period("2016"))
  end

  it "works with extra 0 in month" do
    per = Periods::YearMonth.new("2012", "08")
    expect(per.year).to eq(2012)
    expect(per.month).to eq(8)
  end

  it "works with 2 number month" do
    per = Periods::YearMonth.new("2012", "12")
    expect(per.year).to eq(2012)
    expect(per.month).to eq(12)
  end

  describe "month_of_quarter" do
    it "works" do
      expect(Periods::Year.new(2012).months.map(&:month_of_quarter)).to eq(
        [1, 2, 3,
         1, 2, 3,
         1, 2, 3,
         1, 2, 3]
      )
    end
  end
end
