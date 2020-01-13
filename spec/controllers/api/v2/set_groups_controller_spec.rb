require "rails_helper"

RSpec.describe Api::V2::SetGroupsController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }

  let(:project_without_packages) do
    project = build :project
    project.project_anchor = program.build_project_anchor(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  let(:project_with_packages) do
    project = full_project
    project.project_anchor.update_attributes(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  describe "#index" do
    include_context "basic_context"

    it 'returns empty array for project without payment rules' do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_without_packages.project_anchor.token
      get(:index, params: {})
      resp = JSON.parse(response.body)
      expect(resp["data"]).to eq([])
    end

    it 'returns all payment rules for project with payment rules' do
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project_with_packages.project_anchor.token
      get(:index, params: {})
      resp = JSON.parse(response.body)
      debugger;
      expect(resp["data"].length).to be > 0
      expect(resp["data"].length).to eq(project_with_packages.packages.length)
    end
  end
end
