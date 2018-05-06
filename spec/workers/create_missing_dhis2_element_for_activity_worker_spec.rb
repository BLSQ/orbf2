require "rails_helper"

RSpec.describe CreateMissingDhis2ElementForActivityWorker do
  include_context "basic_context"

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

  def stub_dhis2(method, path)
    stub_request(method, "#{full_project.dhis2_url}/api#{path}")
  end

  def stub_create_dataelement
    stub_dhis2(:post, "/metadata?preheatCache=false")
      .with(body: "{\"dataElements\":[{\"name\":\"long and descriptrive name\",\"shortName\":\"short name\",\"code\":\"code\",\"domainType\":\"AGGREGATE\",\"valueType\":\"NUMBER\",\"aggregationType\":\"SUM\",\"type\":\"int\",\"aggregationOperator\":\"SUM\",\"zeroIsSignificant\":true,\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}")
      .to_return(status: 200, body:  {
        "httpStatus":     "Created",
        "httpStatusCode": 201,
        "status":         "OK",
        "response":       {
          "responseType": "ObjectReport",
          "uid":          "azeaze",
          "klass":        "org.hisp.dhis.dataelement.DataElement"
        }
      }.to_json)
  end

  def stub_default_category_success
    stub_dhis2(:get, "/categoryCombos?fields=:all&filter=name:eq:default")
      .to_return(body: fixture_content(:dhis2, "default_category.json"))
  end

  def stub_find_data_element
    stub_request(:get, "http://play.dhis2.org/demo/api/dataElements?fields=:all&filter=code:eq:code")
      .to_return(status: 200, body: '{"pager":{"page":1,"pageCount":1,"total":1,"pageSize":50},"dataElements": [ {"id":"azeaze", "name":"long and descriptrive name"}]}')
  end
end
