# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dhis2ErrorMessage do
  def rest_client_error(status, body)
    stub_request(:get, "http://dhis2.test/api/dataValueSets").to_return(status: status, body: body)
    RestClient.get("http://dhis2.test/api/dataValueSets")
  rescue RestClient::ExceptionWithResponse => e
    e
  end

  it "adds the dhis2 message and error code of a json error" do
    body = { httpStatus: "Conflict", httpStatusCode: 409, status: "ERROR",
             message: "At least one data element, data set or data element group must be specified",
             errorCode: "E2001" }.to_json

    expect(described_class.call(rest_client_error(409, body))).to eq(
      "409 Conflict: At least one data element, data set or data element group must be specified (E2001)"
    )
  end

  it "adds the dhis2 message when there is no error code" do
    body = { status: "ERROR", message: "Path `$.value` does not contain an STRING but a(n) NUMBER: 5" }.to_json

    expect(described_class.call(rest_client_error(500, body))).to eq(
      "500 Internal Server Error: Path `$.value` does not contain an STRING but a(n) NUMBER: 5"
    )
  end

  it "adds a shortened body when it's not a dhis2 json error" do
    html = "<html><body>#{'Bad Gateway ' * 100}</body></html>"

    message = described_class.call(rest_client_error(502, html))

    expect(message).to start_with("502 Bad Gateway: <html><body>Bad Gateway Bad Gateway")
    expect(message.length).to eq("502 Bad Gateway: ".length + Dhis2ErrorMessage::MAX_BODY_LENGTH)
  end

  it "keeps the message as is without a response body" do
    expect(described_class.call(rest_client_error(503, ""))).to eq("503 Service Unavailable")
  end

  it "keeps the message of other errors" do
    expect(described_class.call(ZeroDivisionError.new("divided by 0"))).to eq("divided by 0")
  end
end
