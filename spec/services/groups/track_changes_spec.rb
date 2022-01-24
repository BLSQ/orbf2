require "rails_helper"

describe Groups::TrackChanges do
  let(:program) do
    create :program
  end
  let(:project_anchor) { create :project_anchor, program: program }
  let(:dhis2_snapshot) {
    project_anchor.dhis2_snapshots.create(
      kind:          "data_elements",
      content:       {},
      dhis2_version: "228",
      year:          "2018",
      month:         "1",
      job_id:        "123"
    )
  }
  it "track changes of simple fields" do
    Groups::TrackChanges.new(
      dhis2_snapshot: dhis2_snapshot,
        current: [
          {
            "id" => "123", "myfield" => "newvalue"
          }
        ], previous: [
          {
            "id" => "123", "myfield" => "oldValue"
          }
        ], whodunnit: "whhhhh"
    ).call
    inspect_changes
    expect(attributes).to eq([{ "dhis2_id"      => "123",
                                "values_before" => { "myfield"=>"oldValue" },
                                "values_after"  => { "myfield"=>"newvalue" },
                                "whodunnit"     => "whhhhh" }])
  end

  it "track changes of arrays" do
    Groups::TrackChanges.new(
      dhis2_snapshot: dhis2_snapshot,
        current: [
          {
            "id" => "123", "myfield" => %w[oldValue newvalue]
          }
        ], previous: [
          {
            "id" => "123", "myfield" => ["oldValue"]
          }
        ], whodunnit: "whhhhh"
    ).call
    inspect_changes
    expect(attributes).to eq([{ "dhis2_id"      => "123",
                                "values_before" => { "myfield"=>["oldValue"] },
                                "values_after"  => { "myfield"=>%w[oldValue newvalue] },
                                "whodunnit"     => "whhhhh" }])
  end

  it "track additions" do
    Groups::TrackChanges.new(
      dhis2_snapshot: dhis2_snapshot,
        current: [
          {
            "id" => "123", "myfield" => "untouch"
          },
          {
            "id" => "456", "myfield" => "newrecord"
          }
        ], previous: [
          {
            "id" => "123", "myfield" => "untouch"
          }
        ], whodunnit: "whhhhh"
    ).call
    inspect_changes
    expect(attributes).to eq(
      [
        { "dhis2_id"      => "456",
          "values_before" => {},
          "values_after"  => {
            "id"      => "456",
            "myfield" => "newrecord"
          },
          "whodunnit"     => "whhhhh" }
      ]
    )
  end

  it "track removal" do
    Groups::TrackChanges.new(
      dhis2_snapshot: dhis2_snapshot,
        current: [], previous: [
          {
            "id" => "123", "myfield" => "untouch"
          }
        ], whodunnit: "whhhhh"
    ).call
    inspect_changes
    expect(attributes).to eq(
      [
        { "dhis2_id"      => "123",
          "values_before" => { "id" => "123", "myfield" => "untouch" },
          "values_after"  => {},
          "whodunnit"     => "whhhhh" }
      ]
    )
  end

  def inspect_changes
    dhis2_snapshot.dhis2_snapshot_changes.each(&:inspect_modifications)
  end

  def attributes
    dhis2_snapshot.dhis2_snapshot_changes.map do |c|
      c.attributes.slice("dhis2_id", "values_before", "values_after", "whodunnit")
    end
  end
end
