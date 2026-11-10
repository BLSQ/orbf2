# frozen_string_literal: true

require "rails_helper"
require_relative "../workers/project_fixture"

# Browserless smoke test of the admin (the system spec needs chrome), mostly
# to catch rails_admin/rails upgrade breakages.
RSpec.describe "Rails Admin", type: :request do
  include ProjectFixture
  include_context "basic_context"

  let!(:project) do
    project = full_project
    project.save!
    user.save!
    project
  end

  def expect_page(path, content = nil)
    get path
    expect(response).to have_http_status(:ok), "GET #{path} : #{response.status}\n#{response.body[0, 500]}"
    expect(response.body).to include(content), "GET #{path} should include #{content.inspect}" if content
  end

  it "renders the dashboard" do
    expect_page("/admin", "Scorpio Admin")
  end

  %w[Program User ProjectAnchor Project PaymentRuleDataset Dhis2Snapshot Dhis2Log].each do |model|
    it "lists #{model}" do
      expect_page("/admin/#{model.underscore}")
    end
  end

  it "shows and edits a project" do
    expect_page("/admin/project/#{project.id}", project.name)
    expect_page("/admin/project/#{project.id}/edit", project.name)
  end

  it "shows and edits a user" do
    expect_page("/admin/user/#{user.id}", user.email)
    expect_page("/admin/user/#{user.id}/edit", user.email)
  end

  it "shows a project anchor" do
    expect_page("/admin/project_anchor/#{project.project_anchor.id}", project.project_anchor.token)
  end
end
