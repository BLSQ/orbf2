
require "rails_helper"

describe Periods do
  describe "fails fast" do
    it "when nil is provided" do
        expect { Periods.from_dhis2_period(nil) }.to raise_error(ArgumentError, "period can't be nil")
    end
    it "when non matching format is provided" do
        expect { Periods.from_dhis2_period("45564sdfsdf") }.to raise_error(ArgumentError,'invalid value for Integer(): "4s"')
    end
  end
end
