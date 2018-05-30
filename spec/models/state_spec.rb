require "rails_helper"

RSpec.describe State, type: :model do
  include_context "basic_context"

  let(:project) do
    Project.new
  end

  let(:state) do
    project.states.build(
      name:       "Maximum Score",
      short_name: "Max Score"
    )
  end

  let(:activity) do
    Activity.new(
      name:       "very_very_long_activity_name",
      short_name: "short_activity_name",
      code:       "activity_code"
    )
  end

  it "should name data elements according to naming pattern" do
    names = state.names(project.naming_patterns, activity, state)
    expect(names).to eq(
      short: "short_activity_name (Max ScoreActivity code)",
      long:  "RBF - Max Score - Activity code very_very_long_activity_name",
      code:  "activity_code - maximum_score"
    )
  end
end
