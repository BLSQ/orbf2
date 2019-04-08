require "rails_helper"

Rails.application.eager_load!

RSpec::Matchers.define :be_paper_trailed do
  # check to see if the model has `has_paper_trail` declared on it
  match do |actual|
    actual.new.respond_to?(:versions)
  end
end

RSpec.describe PaperTrailed do
  EXCEPTIONS = [
    User,
    ActiveRecord::SchemaMigration,
    State,
    PaperTrail::Version,
    Version,
    Dhis2Log,
    Dhis2Snapshot,
    Dhis2SnapshotChange,
    ProjectAnchor,
    InvoicingJob,
    InvoicingSimulationJob,
    Flipper::Adapters::ActiveRecord::Feature,
    Flipper::Adapters::ActiveRecord::Gate,
  ].freeze

  ActiveRecord::Base.descendants
                    .reject(&:abstract_class?)
                    .reject { |m| EXCEPTIONS.include?(m) }
                    .each do |model|

    it "model #{model} should be versioned except #{EXCEPTIONS.map(&:name).join(',')}" do
      expect(model).to be_paper_trailed
    end
  end
end
