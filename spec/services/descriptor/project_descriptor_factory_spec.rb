# frozen_string_literal: true

require "rails_helper"
describe Descriptor::ProjectDescriptorFactory do
  include_context "basic_context"

  let(:expected_descriptor) { JSON.parse(fixture_content(:scorpio, "project_descriptor.json")) }

  it "should serialize to hash usage for invoice coding" do
    project = full_project

    project.payment_rules.first.datasets.create!(frequency: "quarterly", external_reference: "aze123")

    descriptor = described_class.new.project_descriptor(project)
    actual_descriptor = as_json(descriptor)
    puts JSON.generate(descriptor) if actual_descriptor != expected_descriptor

    expect(actual_descriptor).to eq(expected_descriptor)
  end

  def as_json(descriptor)
    JSON.parse(JSON.generate(descriptor))
  end
end
