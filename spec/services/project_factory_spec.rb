require "rails_helper"
describe ProjectFactory do
  it "should instantiate a valid project" do
    project = ProjectFactory.new.build(
      dhis2_url:      "http://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: Program.new(code: "siera").build_project_anchor
    )
    project.valid?
    project.dump_validations
    expect(project.errors.full_messages).to eq []
  end

  def count_all_models
    descendants = ActiveRecord::Base.descendants.reject(&:abstract_class?)
    Hash[descendants.map { |k| [k.name.to_sym, k.count] }]
  end

  it "should instantiate a valid project and publish it" do

    project = ProjectFactory.new.build(
      dhis2_url:      "http://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: Program.new(code: "siera").build_project_anchor
    )
    project.save!

    no_duplications = [
      ActiveRecord::SchemaMigration,
      User,
      State,
      Program,
      ProjectAnchor
    ].map(&:name).map(&:to_sym)
    count_before = count_all_models

    new_draft = project.publish(Date.today.to_date)
    count_after = count_all_models
    count_after.keys.each do |k|
      coeff = no_duplications.include?(k) ? 1 : 2
      count_before[k] ||= 0
      expect(count_after[k]).to eq(count_before[k] * coeff), -> { "#{k} not multiplied by #{coeff} : #{count_after[k]} vs #{count_before[k]}" }
    end

    expect(new_draft.draft?).to eq true
    expect(new_draft.publish_date).to eq nil
    expect(project.draft?).to eq false
    expect(project.publish_date).to eq Date.today.to_date

  end
end
