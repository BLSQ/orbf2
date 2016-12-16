
require "rails_helper"

RSpec.describe Rules::Solver, type: :services do
  let(:solver) { Rules::Solver.new }

describe "mock_values"
  it "should mock for this expression" do
    expect(solver.send(
             :mock_values,
             "SUM(%{attributed_points_values})/SUM(%{max_points_values}) * 100.0",
             ["attributed_points_values","max_points_values"]
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
             "SUM(1, 7) * 100.0",[]
    )).to eq "SUM(1, 7) * 100.0"
  end
end
