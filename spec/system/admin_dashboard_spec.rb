# frozen_string_literal: true

require "rails_helper"

describe "Rails Admin" do
  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  it "can load the dashboard" do
    visit rails_admin.dashboard_url
    expect(page).to have_content "Scorpio Admin"
  end
end
