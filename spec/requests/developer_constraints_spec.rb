require "rails_helper"

RSpec.describe "DeveloperConstraints", type: :request do
  it "raises 404 when not signed in" do
    expect {
      get '/flipper'
    }.to raise_error(ActionController::RoutingError)
  end

  it "resolves with basic auth" do
    ENV["ADMIN_PASSWORD"] = 'abc123'
    auth = ActionController::HttpAuthentication::Basic.encode_credentials("admin", ENV["ADMIN_PASSWORD"])

    get '/flipper', headers: { 'HTTP_AUTHORIZATION' => auth }

    expect(response).to have_http_status(:redirect)
    ENV.delete("ADMIN_PASSWORD")
  end

  it "resolves with developer user" do
    user = FactoryBot.create(:user)
    sign_in user
    ENV["DEV_USER_IDS"] = "a,b,#{user.id}"
    get '/flipper'

    expect(response).to have_http_status(:redirect)
    ENV.delete("DEV_USER_IDS")
  end

  it "raises 404 with normal user" do
    user = FactoryBot.create(:user)
    sign_in user

    expect {
      get '/flipper'
    }.to raise_error(ActionController::RoutingError)
  end
end
