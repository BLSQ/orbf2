# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectAnchor, type: :model do
  describe "#update_token_if_needed" do
    it "does not update if token already set" do
      anchor = ProjectAnchor.new(token: "abc123")
      anchor.update_token_if_needed
      expect(anchor.token).to eq("abc123")
    end

    it "updates if no token set" do
      anchor = ProjectAnchor.new
      anchor.update_token_if_needed
      expect(anchor.token).to_not be_nil
    end

    it "can force_refresh" do
      anchor = ProjectAnchor.new(token: "abc123")
      anchor.update_token_if_needed(force_refresh: true)
      expect(anchor.token).to_not eq("abc123")
      expect(anchor.token).to_not be_nil
    end

    it "returns the token" do
      anchor = ProjectAnchor.new
      new_token = anchor.update_token_if_needed
      expect(anchor.token).to eq(new_token)
    end
  end
end
