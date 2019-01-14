# frozen_string_literal: true

require "rails_helper"

RSpec.describe RuleTypes, kind: :model do
  it "raises on unknown kind" do
    fake_rule = Struct.new(:kind).new(:not_so_kind)
    expect { RuleTypes.from_rule(fake_rule) }.to raise_error RuleTypes::UnsupportedKind
  end

  RuleTypes::RULE_TYPES.each do |kind|
    it "can map default rule(kind: #{kind})" do
      fake_rule = Struct.new(:kind).new(kind)
      expect(RuleTypes.from_rule(fake_rule)).to_not be_nil
    end
  end
end
