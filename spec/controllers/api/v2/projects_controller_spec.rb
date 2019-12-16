require "rails_helper"

RSpec.describe Api::V2::ProjectsController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let!(:project) do
    project = build :project
    project.project_anchor = project_anchor
    project.save!
    project
  end
  describe "#show" do
    it "returns project" do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_anchor.token
      get(:show, params: {})
      resp = JSON.parse(response.body)
      binding.pry
      expect(resp["data"]["id"]).to eq(project.id.to_s)
    end
  end
end
