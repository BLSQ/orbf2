# frozen_string_literal: true

require "rails_helper"

RSpec.describe Oauth::OauthController, type: :controller do
  describe "valid information" do
    let(:program) { FactoryBot.create(:program, oauth_client_id: "test-program", oauth_client_secret: "1234abcd") }
    describe "valid code" do
      it "should redirect to home" do
        FactoryBot.create(:project, project_anchor: program.build_project_anchor)
        dhis2_user_ref = "dhis2userref"
        FactoryBot.create(:user, dhis2_user_ref: dhis2_user_ref)
        
        url_post = program.project_anchor.project.dhis2_url + "/uaa/oauth/token"
        code = "123456"
        access_token = "randomaccesstoken"
        stub_request(:post, url_post).
          with(body: {"code"=>code, "grant_type"=>"authorization_code"}).
          to_return(status: 200, body: "{\"access_token\":\"#{access_token}\",\"token_type\":\"bearer\",\"expires_in\":24526,\"scope\":\"ALL\"}")
        
        url_get = program.project_anchor.project.dhis2_url + "/api/me"
        stub_request(:get, url_get).
          with(headers: {"Authorization"=>"Bearer #{access_token}"}).
          to_return(status: 200, body: "{\"userCredentials\":{\"id\":\"#{dhis2_user_ref}\"}}")

        @request.env["devise.mapping"] = Devise.mappings[:user]
        get :callback, params: { program_id: program.id, code: code }

        expect(response.redirect?).to eq(true)
        expect(response).to redirect_to("/")
      end
    end
  end
end