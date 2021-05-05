# frozen_string_literal: true

require "rails_helper"

describe Periods do
  describe "fails fast" do
    it "when nil is provided" do
      expect { Periods.from_dhis2_period(nil) }.to raise_error(ArgumentError, "period can't be nil")
    end
    it "when non matching format is provided" do
      expect { Periods.from_dhis2_period("45564sdfsdf") }.to raise_error(ArgumentError, 'invalid value for Integer(): "4s"')
    end
  end

  describe "#detect" do
    it "monthly" do
      expect(Periods.detect("202012")).to equal("monthly")
    end

    it "quarterly" do
      expect(Periods.detect("2020Q2")).to equal("quarterly")
    end

    it "yearly" do
      expect(Periods.detect("2020")).to equal("yearly")
    end
    it "sixMonthly" do
      expect(Periods.detect("2020S1")).to equal("sixMonthly")
    end

    it "fails on bad quarterly" do
      expect { Periods.detect("202") }.to raise_error("Unsupported period format : '202'")
    end
  end
end
