# frozen_string_literal: true

require "rails_helper"
require "yaml"
require "json"
require "pathname"

describe "app.json" do
  it "loads from JSON" do
    assert JSON.load(File.open(Rails.root.join("app.json")))
  end
end

describe "locales" do
  yaml_paths = Pathname.glob(Rails.root.join("config", "locales", "*.yml"))

  yaml_paths.each do |path|
    it "load from #{path}" do
      assert YAML.load_file(path)
    end
  end
end
