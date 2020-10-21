require "rails_helper"

RSpec.describe Api::V2::ProjectsController, type: :controller do
  include_context "basic_context"

  let(:program) { create :program }
  let(:token) { "123456789" }
  let!(:project) do
    project = full_project
    project.project_anchor.update_attributes(token: token)
    project.save!
    project
  end

  describe "#show" do
    it "returns project" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project.project_anchor.token
      get(:show, params: {})
      resp = JSON.parse(response.body)

      expect(resp["data"]["id"]).to eq(project.id.to_s)
    end

    it "returns periods" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project.project_anchor.token
      get(:show, params: {})
      resp = JSON.parse(response.body)

      expect(resp["data"]["attributes"]["periods"]).to include("2016Q1")
    end
  end
end
