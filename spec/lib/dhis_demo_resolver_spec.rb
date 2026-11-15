# frozen_string_literal: true

require "rails_helper"
require "dhis_demo_resolver"

RSpec.describe DhisDemoResolver, type: :model do
  it "finds current version" do
    stub_request(:get, "https://play.dhis2.org/demo").to_return(
      status: 302, headers: { location: "https://play.dhis2.org/2.32" }
    )
    stub_request(:get, "https://play.dhis2.org/2.32").to_return(
      status: 302, headers: { location: "https://play.dhis2.org/2.32.0/" }
    )
    stub_request(:get, "https://play.dhis2.org/2.32.0/").to_return(
      status: 302, headers: { location: "https://play.dhis2.org/2.32.0/dhis-web-commons-about/redirect.action" }
    )
    expect(DhisDemoResolver.new.call).to eq("https://play.dhis2.org/2.32.0")
  end

  it "stops before the /login/ redirect of recent versions" do
    stub_request(:get, "https://play.dhis2.org/demo").to_return(
      status: 302, headers: { location: "https://play.im.dhis2.org/stable-2-43-2-1" }
    )
    stub_request(:get, "https://play.im.dhis2.org/stable-2-43-2-1").to_return(
      status: 302, headers: { location: "http://play.im.dhis2.org/stable-2-43-2-1/login/" }
    )
    expect(DhisDemoResolver.new.call).to eq("https://play.im.dhis2.org/stable-2-43-2-1")
  end

  it "follows relative redirects and stops before the dhis-web-login redirect (2.41, 2.42)" do
    stub_request(:get, "https://play.dhis2.org/2.41").to_return(
      status: 302, headers: { location: "https://play.im.dhis2.org/stable-2-41-11" }
    )
    stub_request(:get, "https://play.im.dhis2.org/stable-2-41-11").to_return(
      status: 302, headers: { location: "/stable-2-41-11/" }
    )
    stub_request(:get, "https://play.im.dhis2.org/stable-2-41-11/").to_return(
      status: 302, headers: { location: "http://play.im.dhis2.org/stable-2-41-11/dhis-web-login" }
    )
    expect(DhisDemoResolver.new("https://play.dhis2.org/2.41").call).to eq("https://play.im.dhis2.org/stable-2-41-11")
  end
end
