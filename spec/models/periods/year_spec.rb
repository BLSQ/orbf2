require "rails_helper"

describe Periods::Year do
  let(:yyyy) { "2016" }
  let(:year) { Periods::Year.new(yyyy) }

  it "should have 4 quarters" do
    expect(year.quarters.length).to eq(4)
    expect(year.quarters.map(&:to_year).uniq.first).to eq(year)
  end

  it "should have 12 months" do
    expect(year.months.size).to eq(12)
  end

  it "should implements equals" do
    expect(year.quarters.first.to_year).to eq(year)
  end

  it "should implement to_s" do
    expect(year.to_s).to eq("2016")
  end

  it "should have non verbose inspect" do
    expect(year.inspect).to eq "Periods::Year-2016"
  end

  it "should start and end date" do
    expect(year.start_date.to_s).to eq "2016-01-01"
    expect(year.end_date.to_s).to eq "2016-12-31"
  end
end
