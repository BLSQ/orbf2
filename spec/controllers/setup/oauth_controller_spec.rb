# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::OauthController, type: :controller do

  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      post :create, params: { project_id: FactoryBot.create(:project, project_anchor: FactoryBot.create(:program).build_project_anchor).id }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #create" do
    let!(:user) {
      FactoryBot.create(:user, program: FactoryBot.create(:program))
    }

    before(:each) do
      sign_in user
    end

    describe "dhis2 log-in already enabled" do
      let(:oauth_program) do
        program = FactoryBot.create(:program, oauth_client_id: "somekey", oauth_client_secret: "somesecret")
        FactoryBot.create(:project, project_anchor: program.build_project_anchor)
        user.program = program
        user.save!
        user.reload
        program
      end

      it "should redirect to project home page with a flash message" do
        project = oauth_program.project_anchor.project
        post :create, params: { project_id: project.id }
        expect(response).to redirect_to("/setup/projects/#{project.id}")
        expect(flash[:success]).to eq("DHIS2 log-in already enabled for #{project.name}")
      end
    end

    describe "dhis2 log-in not enabled" do
      describe "request success" do
        let(:program) do
          program = FactoryBot.create(:program)
          FactoryBot.create(:project, project_anchor: program.build_project_anchor)
          user.program = program
          user.save!
          user.reload
          program
        end

        it "should redirect to project home page with a success flash message" do
          project = program.project_anchor.project
          orbf2_url = Scorpio.orbf2_url + "/oauth/#{program.id}/callback"
          uid = "someuid"
          secret = "somesecret"
          
          stub_request(:post, project.dhis2_url + "/api/oAuth2Clients").
            with(
              body: "{\"name\":\"orbf2\",\"cid\":\"orbf2\",\"redirectUris\":[\"#{orbf2_url}\"],\"grantTypes\":[\"authorization_code\"]}").
            to_return(status: 201, body: { response: { uid: uid } }.to_json)

          stub_request(:get, project.dhis2_url + "/api/oAuth2Clients/#{uid}").
            to_return(body: {"secret"=>secret}.to_json)

          post :create, params: { project_id: project.id }

          program.reload

          expect(program.oauth_client_id).to eq("orbf2")
          expect(program.oauth_client_secret).to eq(secret)
          expect(response).to redirect_to("/setup/projects/#{project.id}")
          expect(flash[:success]).to eq("DHIS2 log-in enabled for #{project.name}")
        end
      end

      describe "request failure" do
        let(:program) do
          program = FactoryBot.create(:program)
          FactoryBot.create(:project, project_anchor: program.build_project_anchor)
          user.program = program
          user.save!
          user.reload
          program
        end

        describe "REST conflict - credentials already exist for program" do
          it "should redirect to project home page with a failure flash message" do
            project = program.project_anchor.project
            orbf2_url = Scorpio.orbf2_url + "/oauth/#{program.id}/callback"
            uid = "someuid"
            secret = "somesecret"
            
            stub_request(:post, project.dhis2_url + "/api/oAuth2Clients").
              with(
                body: "{\"name\":\"orbf2\",\"cid\":\"orbf2\",\"redirectUris\":[\"#{orbf2_url}\"],\"grantTypes\":[\"authorization_code\"]}").
              to_return(status: 409)
  
            post :create, params: { project_id: project.id }
  
            program.reload
  
            expect(program.oauth_client_id).to eq(nil)
            expect(program.oauth_client_secret).to eq(nil)
            expect(response).to redirect_to("/setup/projects/#{project.id}")
            expect(flash[:failure]).to be_present
          end
        end
      end
    end
  end
end