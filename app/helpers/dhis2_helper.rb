# frozen_string_literal: true

module Dhis2Helper

  def link_to_org_unit_group(project, dhis2_id, name)
    link_to_dhis2_maintenance(project, "organisationUnitSection/organisationUnitGroup", dhis2_id, name)
  end

  def link_to_debug_orgunit(project, dhis2_id)
    url = "#{project.dhis2_url}/api/organisationUnits/#{dhis2_id}?fields=id,name,organisationUnitGroups[id,name],ancestors[id,name]"
    link_to dhis2_id, url , target: "_blank", class: "external"
  end


  def link_to_dataset(project, dhis2_id)
    link_to_dhis2_maintenance(project, "dataSetSection/dataSet", dhis2_id)
  end

  def link_to_data_element(project, dhis2_id)
    link_to_dhis2_maintenance(project, "dataElementSection/dataElement", dhis2_id)
  end

  def link_to_indicator(project, dhis2_id)
    link_to_dhis2_maintenance(project, "indicatorSection/indicator", dhis2_id)
  end

  def link_to_dhis2_maintenance(project, section, dhis2_id, name = nil)
    url = "#{project.dhis2_url}/dhis-web-maintenance/"\
            "#/edit/#{section}/#{dhis2_id}"
    link_to name || dhis2_id, url, target: "_blank", class: "external"
  end
end
