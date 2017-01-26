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

  it "should publish and create a draft with a copy of all the records linked to project" do
    project = create_project
    no_duplications = [
      ActiveRecord::SchemaMigration,
      User,
      State,
      Program,
      ProjectAnchor,
      Dhis2Snapshot
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
    project = create_project
    project.save!

    new_draft = project.publish(Date.today.to_date)

    expect(new_draft.changelog.size).to eq 3
  end

  def create_project
    project = ProjectFactory.new.build(
      dhis2_url:      "http://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: Program.new(code: "siera").build_project_anchor
    )
    project.build_entity_group(name: "contracted entities", external_reference: "external_reference")

    hospital_group = { name: "Hospital",       organisation_unit_group_ext_ref: "tDZVQ1WtwpA" }
    clinic_group = {   name: "Clinic",         organisation_unit_group_ext_ref: "RXL3lPSK8oG" }
    admin_group = {    name: "Administrative", organisation_unit_group_ext_ref: "w0gFTTmsUcF" }

    default_quantity_states = State.where(name: %w(Claimed Verified Tarif)).to_a
    default_quality_states = State.where(name: ["Claimed", "Verified", "Max. Score"]).to_a
    default_performance_states = State.where(name: ["Claimed", "Max. Score", "Budget"]).to_a
    suffix = ""
    update_package_with_dhis2(
      project.packages[0], suffix, default_quantity_states,
      [clinic_group],
      %w(FTRrcoaog83 P3jJH5Tu5VC FQ2o8UBlcrS M62VHgYT2n0)
    )
    update_package_with_dhis2(
      project.packages[1], suffix, default_quantity_states,
      [hospital_group],
      %w(FTRrcoaog83 P3jJH5Tu5VC FQ2o8UBlcrS M62VHgYT2n0)
    )
    update_package_with_dhis2(
      project.packages[2], suffix, default_quality_states,
      [clinic_group, hospital_group],
      %w(p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2)
    )

    update_package_with_dhis2(
      project.packages[2], suffix, default_performance_states,
      [admin_group],
      %w(p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2)
    )

    project.save!
    project
  end

  def count_all_models
    descendants = ActiveRecord::Base.descendants.reject(&:abstract_class?)
    Hash[descendants.map { |k| [k.name.to_sym, k.count] }]
  end

  def update_package_with_dhis2(package, suffix, states, groups, _acitivity_ids)
    package.name += suffix
    package.states = states
    groups.each_with_index do |group, index|
      package.package_entity_groups[index].update_attributes(group)
    end
  end
end
