# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::WorkersController, type: :controller do
  let(:token) { "123456789" }

  describe "#show" do
    it "returns simulation job" do
      ENV["MONITORING_TOKEN"] = token
      get(:index, params: { token: token })
      expect(response.status).to eq(200)
      JSON.parse(response.body)
    end

    it "return unauthorized when wrong token is provided" do
      get(:index, params: { token: "badtoken" })
      expect(response.status).to eq(401)
    end

    it "return unauthorized when no token is provided" do
      get(:index)
      expect(response.status).to eq(401)
    end
  end
end
