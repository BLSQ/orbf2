
require "rails_helper"

describe Decision::Table do
  let(:table) do
    Decision::Table.new(%(in:level_1,in:level_2,in:level_3,out:equity_bonus
        belgium,*,*,11
        belgium,namur,*,1
        belgium,brussel,*,2
        belgium,brussel,kk,2
      ))
  end

  it "should locate best rule for kk" do
    expect(table.find(level_1: "belgium", level_2: "namur", level_3: "kk")["equity_bonus"]).to eq "1"
  end

  it "should locate best rule for namur" do
    expect(table.find(level_1: "belgium", level_2: "namur")["equity_bonus"]).to eq "1"
  end

  it "should locate best rule for brussel" do
    expect(table.find(level_1: "belgium", level_2: "brussel")["equity_bonus"]).to eq "2"
  end

  it "should locate best rule for the rest of belgium" do
    expect(table.find(level_1: "belgium", level_2: "houtsiplou")["equity_bonus"]).to eq "11"
  end
end
