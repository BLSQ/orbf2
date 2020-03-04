# frozen_string_literal: true
# == Schema Information
#
# Table name: project_anchors
#
#  id         :bigint(8)        not null, primary key
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :integer          not null
#
# Indexes
#
#  index_project_anchors_on_program_id  (program_id)
#
# Foreign Keys
#
#  fk_rails_...  (program_id => programs.id)
#

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
