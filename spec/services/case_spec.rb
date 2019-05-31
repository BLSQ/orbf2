# frozen_string_literal: true

require "rails_helper"

describe Case do
  it "camelize" do
    expect(Case.deep_change([{ demo_sample: "hello" }], :camelize)).to eq(["demoSample"=>"hello"])
  end
  it "underscore" do
    expect(Case.deep_change({ "DemoSample": "hello" }, :underscore)).to eq("demo_sample"=>"hello")
  end
  it "raise error" do
    expect { Case.deep_change({ "DemoSample": "hello" }, :garbage)}.to raise_error(
        RuntimeError, "unsupported case changes garbage vs [:underscore, :camelize]")
  end

end
