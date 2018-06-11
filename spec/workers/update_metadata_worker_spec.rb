require "rails_helper"

require_relative "dhis2_stubs"

RSpec.describe UpdateMetadataWorker do
  include Dhis2Stubs
  include_context "basic_context"

  let(:worker) { described_class.new }

  let(:update_params) {
    {
      "dhis2_id"   => "aze123",
      "name"       => "new_long_long_name",
      "short_name" => "new_short_name",
      "code"       => "new_code"
    }
  }

  it "should update " do
    project = full_project

    stub_find_data_element
    stub_update_data_element

    worker.perform(project.id, update_params)
  end

  def stub_find_data_element
    stub_request(:get, "http://play.dhis2.org/demo/api/dataElements/aze123")
      .to_return(status: 200, body: {
        "id"         => "aze123",
        "name"       => "current long name",
        "short_name" => "current short",
        "code"       => "existing code"
      }.to_json)
  end

  def stub_update_data_element
    stub_request(:put, "http://play.dhis2.org/demo/api/dataElements/aze123")
      .with(body: "{\"id\":\"aze123\",\"name\":\"new_long_long_name\",\"shortName\":\"new_short_name\",\"code\":\"new_code\",\"displayName\":\"current long name\",\"client\":{\"base_url\":\"http://admin:district@play.dhis2.org/demo\",\"verify_ssl\":1,\"timeout\":120,\"debug\":null}}")
      .to_return(status: 200, body: "")
  end
end
