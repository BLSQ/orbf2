# frozen_string_literal: true

require "rails_helper"
require "dhis_demo_resolver"

RSpec.describe DhisDemoResolver, type: :model do
  it "finds current version" do
    stub_request(:get, "https://play.dhis2.org/demo").to_return(
        status: 302, headers: { location: "https://play.dhis2.org/2.32" })
    stub_request(:get, "https://play.dhis2.org/2.32").to_return(
        status: 302, headers: { location: "https://play.dhis2.org/2.32.0/" })
    stub_request(:get, "https://play.dhis2.org/2.32.0/").to_return(
        status: 302, headers: { location: "https://play.dhis2.org/2.32.0/dhis-web-commons-about/redirect.action" })
    expect(DhisDemoResolver.new.call).to eq("https://play.dhis2.org/2.32.0")
  end
end
