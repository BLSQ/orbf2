# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoicingRequest, type: :model do
  it "requires an entity" do
    request = InvoicingRequest.new
    request.valid?
    expect(request.errors[:entity]).to_not be_empty
  end
end
