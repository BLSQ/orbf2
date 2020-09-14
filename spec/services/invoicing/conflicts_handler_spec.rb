# frozen_string_literal: true

require "rails_helper"

describe Invoicing::ConflictsHandler do
  let(:subject) { Invoicing::ConflictsHandler.new({}) }

  blocking_conflicts = [
    # dhis2 stricter "à la liberia"
    { "value" => "Category option combo is required but is not specified", "object" => "2279" },
    { "value" => "Period type of period: 2018Q4 not valid for data element: FC3nR54yGUx", "object" => "2018Q4" },
    { "value" => "Data element: FC3nR54yGUx must be assigned through data sets to organisation unit: UkXuMDgeakb", "object" => "UkXuMDgeakb" },
    { "value" => "Data element not found or not accessible", "object" => "BCexM2Osa2h" },
    # incorrect value type
    { "value" => "Data value is not an integer, must match data element type: PBDIJktKaPs", "object" => "0.39" },
    { "value" => "Data value is not numeric, must match data element type: dlCWZolKtrN", "object" => "tarif" },
    { "value" => "Data value is not a percentage, must match data element type: HXXIlvPZsiK", "object" => "0.9205298013245033" },
    { "value" => "value_not_zero_or_positive_integer, must match data element type: t2mJSsC55ro", "object" => "-1" },
    # future and past periods
    { "value" => "Current date is past expiry days for period 201707 and data set: cYmMsAQK6jw", "object" => "201707" },
    { "value" => "Period: 201807 is not open for this data set at this time: cYmMsAQK6jw", "object" => "uHDCjiYYWyv" },

    # data approval
    { "value" => "Data is already approved for data set: TsLR0wQJknp period: 201901 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0" }
  ]

  non_blocking_conflicts = [
    { "value" => "Value is zero and not significant, must match data element: gNPbU1ccQMz", "object" => "0" },
    { "value" => "Period: 201906 is after latest open future period: 201905 for data element: knwLdaOPObW", "object" => "201906" }
  ]

  blocking_conflicts.each do |blocking|
    it "knows blocking conflicts '#{blocking['value']}'" do
      expect(subject.blocking_conflict?(blocking)).to eq(true)
    end
  end

  non_blocking_conflicts.each do |non_blocking|
    it "knows non-blocking conflicts '#{non_blocking['value']}'" do
      expect(subject.blocking_conflict?(non_blocking)).to eq(false)
    end
  end

  it "assume blocking conflict when unknown" do
    expect(subject.blocking_conflict?("value"=> "we are doomed, this is a new error")).to eq(true)
  end

  describe "should handle status ERROR" do
    let(:raw_status) do
      JSON.parse(fixture_content(:dhis2, "import_error.json"))
    end

    let(:dhis2_status) do
      Dhis2::Status.new(raw_status)
    end
    it "raise an error on status error" do
      expect { Invoicing::ConflictsHandler.new(dhis2_status).raise_if_blocking_conflicts? }.to raise_error(
        Invoicing::PublishingError,
        "The import process failed: Failed to create statement && Import process completed successfully [parallel]"
      )
    end
  end
end
