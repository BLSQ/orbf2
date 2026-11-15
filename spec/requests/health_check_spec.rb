# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ALB health check", type: :request do
  it "answers 200 on /_health without being signed in" do
    get "/_health"

    expect(response).to have_http_status(:ok)
  end

  describe "force_ssl redirect (production) with the app ssl_options" do
    let(:ssl) do
      ActionDispatch::SSL.new(->(_env) { [200, {}, ["app"]] }, **Rails.application.config.ssl_options)
    end

    def plain_http_get(path)
      ssl.call(Rack::MockRequest.env_for("http://10.0.0.1#{path}"))
    end

    it "lets the plain http health check through" do
      status, _headers, = plain_http_get("/_health")

      expect(status).to eq(200), "the ALB health check expects a 200, got #{status}"
    end

    it "still redirects the other plain http requests to https" do
      status, headers, = plain_http_get("/users/sign_in")

      expect([status, headers["Location"]]).to eq([301, "https://10.0.0.1/users/sign_in"])
    end
  end

  it "keeps the health check out of the logs" do
    expect(Rails.application.middleware.map(&:klass)).to include(Rails::Rack::SilenceRequest)
  end
end
