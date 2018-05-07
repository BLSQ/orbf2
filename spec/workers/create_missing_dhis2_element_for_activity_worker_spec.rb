require "rails_helper"
require_relative "dhis2_stubs"

RSpec.describe CreateMissingDhis2ElementForActivityWorker do
  include_context "basic_context"
  include Dhis2Stubs

  let(:worker) { described_class.new }

  it "create a data element and associated activity state" do
    activity, states = full_project.missing_activity_states.first
    state = states.first

    stub_default_category_success
    stub_create_dataelement
    stub_find_data_element

    worker.perform(
      full_project.id,
      "activity_id"  => activity.id,
      "state_id"     => state.id,
      "data_element" => {
        "name"       => "long and descriptrive name",
        "short_name" => "short name",
        "code"       => "code"
      }
    )

    activity_state = activity.activity_states.where(state: state, activity: activity).first
    expect(activity_state.external_reference).to eq("azeaze")
  end
end
