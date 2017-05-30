
shared_context "basic_context" do
  let(:program) do
    create :program, code: "siera"
  end
  let!(:user) do
    FactoryGirl.create(:user, program: program)
  end

  let(:full_project) do
    project = ProjectFactory.new.build(
      dhis2_url:      "http://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: program.build_project_anchor
    )
    project.build_entity_group(name: "contracted entities", external_reference: "external_reference")

    hospital_group = { name: "Hospital",       organisation_unit_group_ext_ref: "tDZVQ1WtwpA" }
    clinic_group = {   name: "Clinic",         organisation_unit_group_ext_ref: "RXL3lPSK8oG" }
    admin_group = {    name: "Administrative", organisation_unit_group_ext_ref: "w0gFTTmsUcF" }

    claimed_state = State.find_by(name: "Claimed")
    verified_state = State.find_by(name: "Verified")
    tarif_state = State.find_by(name: "Tarif")
    max_score_state = State.find_by(name: "Max. Score")

    activity_1 = project.activities.build(
      project: project,
      name: "Vaccination", activity_states_attributes: [
        { name: "Vaccination claimed", state: claimed_state, external_reference: "cl-ext-1" },
        { name: "tarif for Vaccination ", state: tarif_state, external_reference: "tarif-ext-1" }
      ]
    )

    activity_2 = project.activities.build(
      project: project,
      name: "Clients sous traitement ARV suivi pendant les 6 premiers mois", activity_states_attributes: [
        { name: "Clients sous traitement ARV suivi pendant les 6 premiers mois - decl", state: claimed_state, external_reference: "cl-ext-2" },
        { name: "tarif for Clients sous traitement ARV suivi pendant les 6 premiers mois ", state: tarif_state, external_reference: "tarif-ext-2" }
      ]
    )

    project.packages[0].activities = [activity_1, activity_2]
    project.packages[1].activities = [activity_1, activity_2]
    project.packages[2].activities = [activity_1, activity_2]
    project.packages[3].activities = [activity_1, activity_2]

project.packages[0].activity_rule.decision_tables.build(content: fixture_content(:scorpio, "decision_table.csv"))

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
      project.packages[3], suffix, default_performance_states,
      [admin_group],
      %w(p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2)
    )
    project.dump_validations
    project.save!
    project
  end


    def update_package_with_dhis2(package, suffix, states, groups, _acitivity_ids)
      package.name += suffix
      package.states = states
      groups.each_with_index do |group, index|
        package.package_entity_groups[index].assign_attributes(group)
      end
    end
end
