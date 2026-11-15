# frozen_string_literal: true

require "rails_helper"

# the test env disables forgery protection, production does not: turn it on to catch
# a csrf check on the cross-origin token api (dhis2 apps)
RSpec.describe "API v1 cross-origin calls", type: :request do
  let(:project_anchor) { create :project_anchor, token: "123456789", program: create(:program) }
  let(:dhis2_origin) { { "Origin" => "https://dhis2.example.org" } }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def expect_cors_ok(response)
    expect(response).to have_http_status(:ok), "expected 200, got #{response.status}: #{response.body[0, 200]}"
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    expect(response.headers["Access-Control-Allow-Headers"]).to include("X-token")
  end

  # the v1 scope (default: true) catches every /api OPTIONS, v2 paths included
  %w[/api/invoicing_jobs /api/project].each do |path|
    it "answers the OPTIONS preflight of #{path} with the cors headers" do
      process :options, path, headers: dhis2_origin.merge(
        "Access-Control-Request-Method"  => "POST",
        "Access-Control-Request-Headers" => "content-type,x-token"
      )

      expect_cors_ok(response)
    end
  end

  it "accepts a POST without csrf token" do
    post "/api/invoicing_jobs",
         params:  { period: "2016Q1" }.to_json,
         headers: dhis2_origin.merge("Content-Type" => "application/json", "X-Token" => project_anchor.token)

    expect_cors_ok(response)
    expect(JSON.parse(response.body)).to eq("data" => [])
  end
end
