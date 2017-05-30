
require "rails_helper"

RSpec.describe Rules::Solver, type: :services do
  let(:solver) { Rules::Solver.new }

  describe "mock_values"
  it "should mock for this expression" do
    expect(solver.send(
             :mock_values,
             "SUM(%{attributed_points_values})/SUM(%{max_points_values}) * 100.0",
             %w(attributed_points_values max_points_values)
    )).to eq "SUM(1 , 2)/SUM(1 , 2) * 100.0"
  end

  it "should mock for this expression" do
    expect(solver.send(
             :mock_values,
             "SUM(4,6) /SUM(%{max_points_values}) * 100.0",
             ["max_points_values"]
    )).to eq "SUM(4,6) /SUM(1 , 2) * 100.0"
  end

  it "should mock_values" do
    expect(solver.send(
             :mock_values,
             "SUM(1, 7) * 100.0", []
    )).to eq "SUM(1, 7) * 100.0"
  end

  describe "custom functions" do
    let(:calculator) { solver.send(:new_calculator) }

    it "should support safe_div function" do
      expect(calculator.evaluate('safe_div(10,0)')).to eq(0)
      expect(calculator.evaluate('safe_div(5,10)')).to eq(0.5)
    end


    it "should support sum function" do
      expect(calculator.evaluate('sum(10,20,30)')).to eq(60)
      expect(calculator.evaluate('sum(0.5,1.5,2.3)')).to eq(4.3)
    end

    it "should support avg function" do
      expect(calculator.evaluate('avg(10,20,30)')).to eq(20.0)
      expect(calculator.evaluate('avg(10)')).to eq(10.0)
      expect(calculator.evaluate('avg(0.5,1.5,2.3)')).to be_within(0.00000001).of(1.433333333)
    end

    it "should support score_table function" do
      expect(calculator.evaluate('score_table(10, 0,10,0, 10,20,1, 20,30,2)')).to eq(1)
      expect(calculator.evaluate('score_table(20, 0,10,0, 10,20,1, 20,30,2)')).to eq(2)
      expect(calculator.evaluate('score_table(45, 0,10,0, 10,20,1, 20,30,2,10)')).to eq(10)
    end

  end
end
