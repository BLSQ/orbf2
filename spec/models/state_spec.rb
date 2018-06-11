# == Schema Information
#
# Table name: states
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  configurable :boolean          default(FALSE), not null
#  level        :string           default("activity"), not null
#  project_id   :integer          not null
#  short_name   :string
#

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

  let(:dhis2_name) do
    state.names(project.naming_patterns, activity)
  end

  it "should name data elements according to naming pattern" do
    expect(dhis2_name.long).to eq("RBF - Max Score - ACTIVITY_CODE very_very_long_activity_name")
    expect(dhis2_name.short).to eq("short_activity_name (Max ScoreACTIVITY_CODE)")
    expect(dhis2_name.code).to eq("activity_code - maximum_score")
  end

  it "should name data elements according to naming pattern and change project qualifier" do
    project.qualifier = "Pbf"
    expect(dhis2_name.long).to eq("Pbf - Max Score - ACTIVITY_CODE very_very_long_activity_name")
    expect(dhis2_name.short).to eq("short_activity_name (Max ScoreACTIVITY_CODE)")
    expect(dhis2_name.code).to eq("activity_code - maximum_score")
  end

  it "should name DHIS2 data elements according to naming pattern and return a Dhis2Name Class" do
    expect(dhis2_name).to eq(
      Dhis2Name.new(
        long:  "RBF - Max Score - ACTIVITY_CODE very_very_long_activity_name",
        short: "short_activity_name (Max ScoreACTIVITY_CODE)",
        code:  "activity_code - maximum_score"
      )
    )
  end
end
