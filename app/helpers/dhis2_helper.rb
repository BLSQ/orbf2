
module Dhis2Helper
  def link_to_data_element(project, dhis2_id)
    url = "#{project.dhis2_url}/dhis-web-maintenance/"\
            "#/edit/dataElementSection/dataElement/#{dhis2_id}"
    link_to dhis2_id, url, target: "_blank", class: "external"
  end
end
