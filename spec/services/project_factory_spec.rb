require "rails_helper"
describe ProjectFactory do
  include_context "basic_context"

  it "should instantiate a valid project" do
    project = full_project
    project.valid?
    project.dump_validations
    expect(project.errors.full_messages).to eq []
  end

  it "should publish and create a draft with a copy of all the records linked to project" do
    project = full_project
    no_duplications = [
      ActiveRecord::SchemaMigration,
      User,
      State,
      Program,
      ProjectAnchor,
      Dhis2Snapshot,
      Dhis2Log,
      Version,
      PaperTrail::Version,
      PaperTrail::VersionAssociation
    ].map(&:name).map(&:to_sym)
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

  it "should publish and create a draft with a copy of all the records linked to project" do
    project = full_project
    project.save!

    new_draft = project.publish(Date.today.to_date)

    expect(new_draft.changelog.size).to eq 3
  end



  def count_all_models
    descendants = ActiveRecord::Base.descendants.reject(&:abstract_class?)
    Hash[descendants.map { |k| [k.name.to_sym, k.count] }]
  end

end
