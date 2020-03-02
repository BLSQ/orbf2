
module Dhis2SnapshotFixture



  def stub_system_info(project)
    stub_request(:get, "#{project.dhis2_url}/api/system/info")
      .to_return(status: 200, body: '{"version":"1.0"}')
  end

  def stub_organisation_units(project)
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnits?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
      .to_return(status: 200, body: fixture_content(:dhis2, "all_organisation_units_with_groups.json"))
  end

  def stub_organisation_unit_groups(project)
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))
  end

  def stub_data_elements(project)
    stub_request(:get, "#{project.dhis2_url}/api/dataElements?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
      .to_return(status: 200, body: fixture_content(:dhis2, "data_elements.json"))
  end

  def stub_data_elements_groups(project)
    stub_request(:get, "#{project.dhis2_url}/api/dataElementGroups?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
      .to_return(status: 200, body: fixture_content(:dhis2, "data_element_groups.json"))
  end

  def stub_indicators(project)
    stub_request(:get, "#{project.dhis2_url}/api/indicators?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
      .to_return(status: 200, body: fixture_content(:dhis2, "indicators.json"))
  end

  def stub_organisation_unit_group_sets(project)
    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroupSets?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisation_unit_group_sets.json"))
  end

  def stub_category_combos(project)
    stub_request(:get, "#{project.dhis2_url}/api/categoryCombos?fields=id,name,code,categoryOptionCombos[id,name,code]&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}").to_return(status: 200, body: fixture_content(:dhis2, "category_combos.json"))
  end

  def stub_all_snapshots(project, month = "201803")
    stub_snapshots(project, month)
  end

  def stub_snapshots(project, month = "201803")
    stub_organisation_unit_group_sets(project)
    stub_organisation_unit_groups(project)
    stub_organisation_units(project)
    stub_system_info(project)

    stub_data_elements(project)
    stub_data_elements_groups(project)
    stub_indicators(project)
    stub_category_combos(project)

    Dhis2SnapshotWorker.new.perform(
      project.project_anchor.id,
      now: Periods.from_dhis2_period(month).end_date
    )
    WebMock.reset!
  end
end
