# frozen_string_literal: true

require "rails_helper"

describe ProjectFactory do
  include_context "basic_context"

  it "should instantiate a valid project" do
    project = full_project
    project.valid?
    project.dump_validations
    expect(project.errors.full_messages).to eq []
  end

  it "should be able to destroy" do
    project = full_project
    project.save!
    project.destroy!
  end

  INFRA_AR = [
    ActiveRecord::SchemaMigration,
    ActiveStorage::Attachment,
    ActiveStorage::Blob,
    PaperTrail::Version,
    PaperTrail::VersionAssociation,
    Flipper::Adapters::ActiveRecord::Feature,
    Flipper::Adapters::ActiveRecord::Gate
  ].freeze

  NON_PROJECT_AR = [
    User,
    Program,
    ProjectAnchor,
    Dhis2Snapshot,
    Dhis2SnapshotChange,
    Dhis2Log,
    InvoicingJob,
    InvoicingSimulationJob,
    Version
  ].freeze

  EXCEPTIONS = INFRA_AR + NON_PROJECT_AR

  it "should publish and create a draft with a copy of all the records linked to project" do
    project = full_project
    no_duplications = EXCEPTIONS.map(&:name).map(&:to_sym)
    project.payment_rules.first.datasets.create!(frequency: "quarterly", external_reference: "fakedsid")
    count_before = count_all_models
    new_draft = project.publish(Date.today.to_date)
    count_after = count_all_models
    count_after.keys.each do |k|
      coeff = no_duplications.include?(k) ? 1 : 2
      count_before[k] ||= 0
      expect(count_after[k]).to be > 0, "#{k} must be > 0" unless no_duplications.include?(k)
      expect(count_after[k]).to eq(count_before[k] * coeff), -> { "#{k} not multiplied by #{coeff} : #{count_after[k]} vs #{count_before[k]}" }
    end

    expect(new_draft.draft?).to eq true
    expect(new_draft.publish_date).to eq nil
    expect(project.draft?).to eq false
    expect(project.publish_date).to eq Date.today.to_date
  end

  it "should publish and create a draft with a copy of all the records linked to project with correct project_id" do
    project = full_project
    project.save!
    project.payment_rules.first.datasets.create!(frequency: "monthly", external_reference: "demodataset")

    new_draft = project.publish(Date.today.to_date)
    expect(new_draft.changelog.size).to(eq(0))

    descendants_with_project_id = ActiveRecord::Base.descendants
                                                    .reject(&:abstract_class?)
                                                    .reject { |klass| EXCEPTIONS.include?(klass) }

    descendants_with_project_id.each do |model|
      counters = count_by_project_id(model.all)
      # puts model.name + " => " + counters.to_json
      expect(counters[project.id]).to eq(counters[new_draft.id])
      expect(counters[project.id]).to be >= 0
    end
  end

  def descendants_with_project_id
    ActiveRecord::Base.descendants
                      .reject(&:abstract_class?)
                      .reject { |klass| EXCEPTIONS.include?(klass) }
  end

  def count_by_project_id(arr)
    Hash[arr.group_by(&:project_id).map { |k, v| [k, v.size] }]
  end

  def count_all_models
    descendants = ActiveRecord::Base.descendants.reject(&:abstract_class?)
    Hash[descendants.map { |k| [k.name.to_sym, k.count] }]
  end
end
