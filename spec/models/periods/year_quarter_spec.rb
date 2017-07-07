require "rails_helper"

describe Periods::YearQuarter do
  let(:yyyyqq) { "2016Q2" }
  let(:year_quarter) { Periods::YearQuarter.from_yyyyqq(yyyyqq) }
  let(:last_quarter) { Periods::YearQuarter.from_yyyyqq("2016Q4") }

  describe "#from_yyyyqq" do
    it "should return yyyyqq" do
      expect(year_quarter.yyyyqq).to eq yyyyqq
    end

    it "should use it as equality" do
      expect(year_quarter).to eq Periods::YearQuarter.from_yyyyqq(yyyyqq)
    end

    it "should use it for non equality" do
      expect(year_quarter).not_to eq last_quarter
    end

    it "can use it as uniqueness" do
      expect(
        [Periods::YearQuarter.from_yyyyqq(yyyyqq),
         Periods::YearQuarter.from_yyyyqq(yyyyqq)].uniq.size
      ).to eq 1
    end
  end

  describe "#from_year_month" do
    it "should return quater" do
      expect(Periods::YearQuarter.from_year_month(2016, 1).to_s).to eq "2016Q1"
      expect(Periods::YearQuarter.from_year_month(2016, 2).to_s).to eq "2016Q1"
      expect(Periods::YearQuarter.from_year_month(2016, 3).to_s).to eq "2016Q1"
      expect(Periods::YearQuarter.from_year_month(2016, 4).to_s).to eq "2016Q2"
      expect(Periods::YearQuarter.from_year_month(2016, 5).to_s).to eq "2016Q2"
      expect(Periods::YearQuarter.from_year_month(2016, 6).to_s).to eq "2016Q2"
      expect(Periods::YearQuarter.from_year_month(2016, 7).to_s).to eq "2016Q3"
      expect(Periods::YearQuarter.from_year_month(2016, 8).to_s).to eq "2016Q3"
      expect(Periods::YearQuarter.from_year_month(2016, 9).to_s).to eq "2016Q3"
      expect(Periods::YearQuarter.from_year_month(2016, 10).to_s).to eq "2016Q4"
      expect(Periods::YearQuarter.from_year_month(2016, 11).to_s).to eq "2016Q4"
      expect(Periods::YearQuarter.from_year_month(2016, 12).to_s).to eq "2016Q4"
    end
  end

  describe "#quarter" do
    it "should return quarter number" do
      expect(year_quarter.quarter).to eq 2
    end
  end
  describe "#year" do
    it "should return year number" do
      expect(year_quarter.year).to eq 2016
    end
  end
  describe "#months" do
    it "should iterate through months of the quarter" do
      expect(year_quarter.months.map(&:name)).to eq %w[April May June]
      expect(last_quarter.months.map(&:name)).to eq %w[October November December]
    end
  end

  describe "#to_year" do
    it "should return year value" do
      expect(year_quarter.to_year.year).to eq 2016
    end
  end

  describe "#inspect" do
    it "should have non verbose inspect" do
      expect(year_quarter.inspect).to eq "Periods::YearQuarter-2016Q2"
    end
  end
end
