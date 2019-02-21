# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rules::ValuesMocker, type: :services do
  it "substitute %{_values} with a '1, 2' for double occurance" do
    expect(Rules::ValuesMocker.mock_values(
             "SUM(%{attributed_points_values})/SUM(%{max_points_values}) * 100.0",
             %w[attributed_points_values max_points_values]
           )).to eq "SUM(1 , 2)/SUM(1 , 2) * 100.0"
  end

  it "substitute %{_values} with a '1, 2' for single occurance" do
    expect(Rules::ValuesMocker.mock_values(
             "SUM(4,6) /SUM(%{max_points_values}) * 100.0",
             ["max_points_values"]
           )).to eq "SUM(4,6) /SUM(1 , 2) * 100.0"
  end

  it "leave expression untouched if no %{_values}" do
    expect(Rules::ValuesMocker.mock_values(
             "SUM(1, 7) * 100.0", []
           )).to eq "SUM(1, 7) * 100.0"
  end

  it "substitute %{last_x_quarters_window_values} with a correct size equations" do
    expect(Rules::ValuesMocker.mock_values(
             "SUM(4,6) /SUM(%{demo_last_3_quarters_window_values}) * 100.0",
             ["demo_last_3_quarters_window_values"]
           )).to eq "SUM(4,6) /SUM(1 , 2 , 3) * 100.0"
  end

  it "substitute %{last_x_months_window_values} with a correct size equations" do
    expect(Rules::ValuesMocker.mock_values(
             "SUM(4,6) /SUM(%{demo_last_7_months_window_values}) * 100.0",
             ["demo_last_7_months_window_values"]
           )).to eq "SUM(4,6) /SUM(1 , 2 , 3 , 4 , 5 , 6 , 7) * 100.0"
  end

  it "substitute %{_current_quarter_values} with a correct size equations" do
    expect(Rules::ValuesMocker.mock_values(
             "SUM(4,6) / SUM(%{demo_current_quarter_values}) * 100.0",
             ["demo_current_quarter_values"]
           )).to eq "SUM(4,6) / SUM(1 , 2 , 3) * 100.0"
  end

end
