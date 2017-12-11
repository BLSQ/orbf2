require "rails_helper"
require_relative "../../workers/dhis2_snapshot_fixture"

RSpec.describe Invoicing::EntityBuilder do
  include Dhis2SnapshotFixture
  include_context "basic_context"

  let(:program) { create :program }

  let(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program
    project
  end

  let(:pyramid) { mock_pyramid }
  let(:entity_builder) { Invoicing::EntityBuilder.new }

  it "should find facts " do
    org_unit = pyramid.org_unit("vRC0stJ5y9Q")
    expect(entity_builder.to_entity(org_unit).facts).to eq(
      "level_1"                            => "ImspTQPwCqd",
      "level_2"                            => "O6uvpzGd5pu",
      "level_3"                            => "U6Kr7Gtpidn",
      "level_4"                            => "vRC0stJ5y9Q",
      "level"                              => "4",
      "groupset_code_facility_ownership"   => "private_clinic",
      "groupset_code_facility_type"        => "clinic",
      "groupset_code_location_rural_urban" => "rural"
    )
  end

  def mock_pyramid
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=id,displayName,path,organisationUnitGroups&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "all_organisation_units_with_groups.json"))
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=id,displayName&pageSize=20000")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))
    stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnitGroupSets?fields=id,displayName&pageSize=20000")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisation_unit_group_sets.json"))
    Pyramid.from(project)
  end
end
