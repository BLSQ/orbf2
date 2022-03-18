# frozen_string_literal: true

require "rails_helper"

RSpec.describe Oauth::OauthController, type: :controller do
  describe "#dhis2_login" do
    let!(:program) { 
      program = FactoryBot.create(:program, oauth_client_id: "test-program", oauth_client_secret: "1234abcd")
      FactoryBot.create(:project, project_anchor: program.build_project_anchor)
      program
    }

    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe "valid information" do
      it "should redirect to the DHIS2 authorize URL" do
        get :dhis2_login, params: { program_id: program.id }
        
        oauth_client_id = program.oauth_client_id
        url_redirect = program.project_anchor.project.dhis2_url + "/uaa/oauth/authorize?client_id=#{oauth_client_id}&response_type=code"

        expect(response).to redirect_to(url_redirect)
      end
    end

    describe "invalid information" do
      describe "program does not exist" do
        it "should redirect to users sign-in" do
          get :dhis2_login, params: { program_id: "123456" }
  
          expect(response).to redirect_to("/users/sign_in")
        end
      end
      
      describe "program is not configured for oauth" do
        it "should redirect to users sign-in" do
          program = FactoryBot.create(:program)
          
          get :dhis2_login, params: { program_id: program.id}
  
          expect(response).to redirect_to("/users/sign_in")
        end
      end
    end
  end

  describe "#callback" do
    let!(:program) { 
      program = FactoryBot.create(:program, oauth_client_id: "test-program", oauth_client_secret: "1234abcd")
      FactoryBot.create(:project, project_anchor: program.build_project_anchor)
      program
    }
    
    let(:user) { 
      FactoryBot.create(:user, dhis2_user_ref: "dhis2userref", program_id: program.id) 
    }

    let(:code) { "123456" }

    let(:access_token) { "randomaccesstoken" } 

    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe "valid information" do
      it "should redirect to home" do
        stub_request(:post, program.project_anchor.project.dhis2_url + "/uaa/oauth/token").
          with(body: {"code"=>code, "grant_type"=>"authorization_code"}).
          to_return(status: 200, body: "{\"access_token\":\"#{access_token}\",\"token_type\":\"bearer\",\"expires_in\":24526,\"scope\":\"ALL\"}")

        stub_request(:get, program.project_anchor.project.dhis2_url + "/api/me").
          with(headers: {"Authorization"=>"Bearer #{access_token}"}).
          to_return(status: 200, body: "{\"id\":\"#{user.dhis2_user_ref}\"}")

        get :callback, params: { program_id: program.id, code: code }

        expect(response.redirect?).to eq(true)
        expect(response).to redirect_to("/")
      end
    end

    describe "invalid information" do
      describe "invalid code" do
        it "should redirect to users sign-in" do
          stub_request(:post, program.project_anchor.project.dhis2_url + "/uaa/oauth/token").
            with(body: {"code"=>code, "grant_type"=>"authorization_code"}).
            to_return(status: 400, body: "{\"error\":\"invalid_grant\",\"error_description\":\"Invalid authorization code: #{code}\"}")
   
          get :callback, params: { program_id: program.id, code: "123456" }

          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "program does not exist" do
        it "should redirect to users sign-in" do
          @request.env["devise.mapping"] = Devise.mappings[:user]

          get :callback, params: { program_id: 8912, code: "123456" }

          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "user not found based on dhis2_user_ref" do
        it "should redirect to users sign-in" do
          stub_request(:post, program.project_anchor.project.dhis2_url + "/uaa/oauth/token").
          with(body: {"code"=>code, "grant_type"=>"authorization_code"}).
          to_return(status: 200, body: "{\"access_token\":\"#{access_token}\",\"token_type\":\"bearer\",\"expires_in\":24526,\"scope\":\"ALL\"}")

          stub_request(:get, program.project_anchor.project.dhis2_url + "/api/me").
            with(headers: {"Authorization"=>"Bearer #{access_token}"}).
            to_return(status: 200, body: "{\"id\":\"unknownuserref\"}")

          get :callback, params: { program_id: program.id, code: code }

          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "bad response from DHIS2 when returning access token" do
        it "should redirect to users sign-in" do
          stub_request(:post, program.project_anchor.project.dhis2_url + "/uaa/oauth/token").
          with(body: {"code"=>code, "grant_type"=>"authorization_code"}).
          to_return(status: 200, body: "<p>DHIS2 timeout</p>")

          get :callback, params: { program_id: program.id, code: code }

          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "bad response from DHIS2 when returning user info" do
        it "should redirect to users sign-in" do
          stub_request(:post, program.project_anchor.project.dhis2_url + "/uaa/oauth/token").
          with(body: {"code"=>code, "grant_type"=>"authorization_code"}).
          to_return(status: 200, body: "{\"access_token\":\"#{access_token}\",\"token_type\":\"bearer\",\"expires_in\":24526,\"scope\":\"ALL\"}")

          stub_request(:get, program.project_anchor.project.dhis2_url + "/api/me").
            with(headers: {"Authorization"=>"Bearer #{access_token}"}).
            to_return(status: 200, body: "<p>DHIS2 timeout</p>")

          get :callback, params: { program_id: program.id, code: code }

          expect(response).to redirect_to("/users/sign_in")
        end
      end
    end
  end
end