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

describe "ruby version" do
  it "Gemfile and .ruby_version match" do
    ruby_version = File.read(".ruby-version").strip
    gemfile_ruby_version = File.readlines("Gemfile").grep(/^ruby/).first.gsub("ruby ", "").gsub('"', '').strip

    assert ruby_version == gemfile_ruby_version, ".ruby-version (#{ruby_version}) needs to have the same version as Gemfile (#{gemfile_ruby_version})"
  end
end
