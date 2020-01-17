require "rails_helper"

DEFAULT_ACCEPT="application/vnd.api+json;version=2"

RSpec.describe "Api V2", type: :request do
  let(:url) { "/api/project" }

  it "raises 404 when no accept header set" do
    expect {
      get url
    }.to raise_error(ActionController::RoutingError)
  end

  it "raises 404 when different version accept header is set" do
    expect {
      get url, params: {}, headers: {
            "Accept" => "application/vnd.api+json;version=3"
          }
    }.to raise_error(ActionController::RoutingError)
  end

  describe '401' do
    it "no token" do
      get url, params: {}, headers: {
            "Accept" => DEFAULT_ACCEPT
          }
      expect(response.status).to eq(401)
    end

    it "invalid params token" do
      get url, params: {token: 'abc123'}, headers: {
            "Accept" => DEFAULT_ACCEPT
          }
      expect(response.status).to eq(401)
    end

    it "invalid header token" do
      get url, params: {}, headers: {
            "Accept" => DEFAULT_ACCEPT,
            "X-Token" => "abc123"
          }
      expect(response.status).to eq(401)
    end
  end

  describe 'authorized' do
    let(:token) { "abc123" }

    before do
      create :project_anchor, token: token
    end

    it "valid token in header" do
      get url, params: {}, headers: {
            "Accept" => DEFAULT_ACCEPT,
            "X-Token" => token
          }
      expect(response.status).to eq(200)
    end

    it "valid token in params" do
      get url, params: { token: token }, headers: {"Accept" => DEFAULT_ACCEPT}

      expect(response.status).to eq(200)
    end
  end

end
