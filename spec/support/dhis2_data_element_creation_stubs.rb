# frozen_string_literal: true

# webmock stubs of the dhis2 calls made by DataElementCreator
module Dhis2DataElementCreationStubs
  def stub_default_category_combo(project)
    stub_request(:get, "#{project.dhis2_url}/api/categoryCombos")
      .with(query: { "fields" => ":all", "filter" => "name:eq:default" })
      .to_return(body: { categoryCombos: [{ id: "p0KPaWEg3cf", name: "default" }] }.to_json)
  end

  def stub_metadata_import(project, status: 200, body: { status: "OK", typeReports: [] })
    stub_request(:post, "#{project.dhis2_url}/api/metadata?preheatCache=false")
      .to_return(status: status, body: body.to_json)
  end

  def stub_data_element_by_code(project, code, found_id)
    found = found_id ? [{ id: found_id, name: "found" }] : []
    stub_request(:get, "#{project.dhis2_url}/api/dataElements")
      .with(query: { "fields" => ":all", "filter" => "code:eq:#{code}" })
      .to_return(body: { pager: { page: 1, pageCount: 1, total: found.size }, dataElements: found }.to_json)
  end

  # metadata import report of dhis2 2.35 refusing an object
  def refused_import_report(message)
    {
      status:      "ERROR",
      typeReports: [
        {
          klass:         "org.hisp.dhis.dataelement.DataElement",
          objectReports: [{ errorReports: [{ message: message, errorCode: "E5003" }] }]
        }
      ]
    }
  end
end

RSpec.configure do |config|
  config.include Dhis2DataElementCreationStubs
end
