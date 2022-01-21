# frozen_string_literal: true

module Dhis2Helper
  def link_to_org_unit_group(project, dhis2_id, name)
    link_to_dhis2_maintenance(project, "organisationUnitSection/organisationUnitGroup", dhis2_id, name)
  end

  def link_to_debug_orgunit(project, dhis2_id)
    url = "#{project.dhis2_url}/api/organisationUnits/#{dhis2_id}?fields=id,name,organisationUnitGroups[id,name],ancestors[id,name]"
    link_to dhis2_id, url, target: "_blank", class: "external"
  end

  def link_to_dataset(project, dhis2_id)
    link_to_dhis2_maintenance(project, "dataSetSection/dataSet", dhis2_id)
  end

  def link_to_data_element(project, dhis2_id)
    # This could be a combined dhis2_id, like a data_element separated
    # with a `.`, so always try to split and get the first one before
    # a dot.
    data_element_ext_ref = (dhis2_id || "").split(".").first
    link_to_dhis2_maintenance(project, "dataElementSection/dataElement", data_element_ext_ref)
  end

  def link_to_indicator(project, dhis2_id)
    link_to_dhis2_maintenance(project, "indicatorSection/indicator", dhis2_id)
  end

  def link_to_coc(project, dhis2_id)
    return content_tag(:span, "dhis2_id was not set", class: "text-danger") unless dhis2_id

    link_to_dhis2_maintenance(project, "categorySection/categoryOptionCombo", dhis2_id)
  end

  def link_to_dhis2_maintenance(project, section, dhis2_id, name = nil)
    url = "#{project.dhis2_url}/dhis-web-maintenance/"\
            "#/edit/#{section}/#{dhis2_id}"
    link_to name || dhis2_id, url, target: "_blank", class: "external"
  end
end
