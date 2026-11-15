# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::HesabuManagerController, type: :controller do
  describe "when not authenticated" do
    it "redirects show to sign in" do
      get :show
      expect(response).to redirect_to("/users/sign_in")
    end

    it "does not proxy dhis2" do
      get :dhis2, params: { path: "dataElements" }
      expect(response).to redirect_to("/users/sign_in")
      expect(WebMock).not_to have_requested(:any, /play.dhis2.org/)
    end
  end

  describe "when authenticated" do
    include_context "basic_context"

    let!(:project) { full_project.tap(&:save!) }

    before { sign_in user }

    describe "#show" do
      let(:build_dir) { Pathname.new(Dir.mktmpdir) }

      before { stub_const("#{described_class}::BUILD_DIR", build_dir) }
      after { FileUtils.rm_rf(build_dir) }

      def manager_config
        json = response.body[%r{window.HESABU_CONFIG = (.*?);</script>}, 1]
        expect(json).not_to be_nil, "no HESABU_CONFIG in #{response.body}"
        JSON.parse(json)
      end

      it "tells how to install the manager when the build is missing" do
        get :show
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("rake hesabu_manager:install")
      end

      it "serves the manager with the project token and the orbf2 user" do
        build_dir.join("index.html").write(%(<html><head><title>Hesabu</title></head><body></body></html>))

        get :show

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(<head><base href="/hesabu-manager/"><script>))
        project_anchor = project.project_anchor.reload
        expect(project_anchor.token).to be_present
        expect(manager_config).to eq(
          "token"       => project_anchor.token,
          "url"         => "http://test.host",
          "dhis2ApiUrl" => "http://test.host/setup/manager/dhis2/api",
          "dhis2Url"    => "http://play.dhis2.org/demo",
          "user"        => { "id" => "orbf2-#{user.id}", "displayName" => user.email, "canEdit" => true }
        )
      end

      it "escapes the config so it can't close the script tag" do
        build_dir.join("index.html").write("<html><head></head></html>")
        user.update!(email: "x</script>@example.com")

        get :show

        expect(response.body).not_to include("x</script>")
        expect(manager_config["user"]["displayName"]).to eq("x</script>@example.com")
      end
    end

    describe "#dhis2" do
      it "forwards allowed reads with the project credentials and the query string" do
        dhis2 = stub_request(:get, "http://play.dhis2.org/demo/api/dataElements?fields=id,name&filter=name:ilike:anc")
                .with(basic_auth: %w[admin district])
                .to_return(status: 200, body: { dataElements: [{ id: "de1" }] }.to_json)

        get :dhis2, params: { path: "dataElements", fields: "id,name", filter: "name:ilike:anc" }

        expect(dhis2).to have_been_requested
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/json")
        expect(JSON.parse(response.body)).to eq("dataElements" => [{ "id" => "de1" }])
      end

      it "forwards nested paths and dhis2 errors" do
        stub_request(:get, "http://play.dhis2.org/demo/api/identifiableObjects/unknown.json")
          .to_return(status: 404, body: { httpStatus: "Not Found" }.to_json)

        get :dhis2, params: { path: "identifiableObjects/unknown.json" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq("httpStatus" => "Not Found")
      end

      %w[dataValueSets me system/info dataStore/hesabu/hesabu ../dataElements dataElements/..%2f].each do |path|
        it "refuses #{path}" do
          get :dhis2, params: { path: path }

          expect(response).to have_http_status(:forbidden)
          expect(WebMock).not_to have_requested(:any, /play.dhis2.org/)
        end
      end
    end
  end
end
