# frozen_string_literal: true

require "rails_helper"

describe "Immigrant check" do
  it "verifies no missing foreign key constraints" do
    Rails.application.eager_load!

    Immigrant.ignore_keys = [
      { from_table: "version_associations", column: "version_id" },
      { from_table: "versions", column: "whodunnit" },
      # flipper 1.x declares gates belongs_to feature (by key), flipper's schema has no FK
      { from_table: "flipper_gates", column: "feature_key" }
    ]

    keys, warnings = Immigrant::KeyFinder.new.infer_keys
    warnings.values.each { |warning| puts "WARNING: #{warning}" }

    keys.each do |key|
      column = key.options[:column]
      pk = key.options[:primary_key]
      puts "Missing foreign key relationship on '#{key.from_table}.#{column}' to '#{key.to_table}.#{pk}'"
    end

    if keys.any?
      raise "Found missing foreign keys, run `rails generate immigration MigrationName` to create a migration to add them. #{keys}"
    end
  end
end
