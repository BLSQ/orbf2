require "rails_helper"

RSpec.describe ProjectsController, type: :controller do
  describe "When non authenticated #index" do
    it "should redirect to sign on" do
      post :create
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    it "should allow project creation when valid infos is passed" do
      stub_system_info_success

      post :create, project: {
        name: "project_name",
        dhis2_url: "https://sample.local/",
        user: "username",
        password: "password", bypass_ssl: false
      }
      expect(response).to redirect_to("/")
      expect(flash[:notice]).to eq "Great your dhis2 connection looks valid !"
      user.reload
      expect(user.project.name).to eq("project_name")
    end

    def stub_system_info_success
      stub_request(:get, "https://sample.local/api/system/info")
        .with(headers: { "Accept" => "application/json", "Accept-Encoding" => "gzip, deflate", "Authorization" => "Basic dXNlcm5hbWU6cGFzc3dvcmQ=", "Content-Type" => "application/json", "Host" => "sample.local", "User-Agent" => "rest-client/2.0.0 (linux-gnu x86_64) ruby/2.3.1p112" })
        .to_return(status: 200, body: '{ "version":"2.25" }', headers: {})
    end

    def stub_system_info_ko
      stub_request(:get, "https://sample.local/api/system/info")
        .with(headers: { "Accept" => "application/json", "Accept-Encoding" => "gzip, deflate", "Authorization" => "Basic dXNlcm5hbWU6cGFzc3dvcmQ=", "Content-Type" => "application/json", "Host" => "sample.local", "User-Agent" => "rest-client/2.0.0 (linux-gnu x86_64) ruby/2.3.1p112" })
        .to_return(status: 200, body: '{ "version":"2.25" }', headers: {})
    end

  end
end
