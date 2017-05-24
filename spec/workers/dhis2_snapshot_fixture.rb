
module Dhis2SnapshotFixture
  def stub_system_info
    stub_request(:get, "#{project.dhis2_url}/api/system/info")
      .to_return(status: 200, body: '{"version":"1.0"}')
  end

  def stub_organisation_units
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "all_organisation_units_with_groups.json"))
  end

  def stub_organisation_unit_groups
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))
  end

  def stub_data_elements
    stub_request(:get, "#{project.dhis2_url}/api/dataElements?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "data_elements.json"))
  end

  def stub_data_elements_groups
    stub_request(:get, "#{project.dhis2_url}/api/dataElementGroups?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "data_element_groups.json"))
  end

  def stub_indicators
    stub_request(:get, "http://play.dhis2.org/demo/api/indicators?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "indicators.json"))
  end

  def stub_organisation_unit_group_sets
    stub_request(:get, "http://play.dhis2.org/demo/api/organisationUnitGroupSets?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisation_unit_group_sets.json"))
  end
end
