
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

    [
      { name: "Claimed",           configurable: false,  level: "activity" },
      { name: "Verified",          configurable: false,  level: "activity" },
      { name: "Validated",         configurable: false,  level: "activity" },
      { name: "Max. Score",        configurable: true,   level: "activity" },
      { name: "Tarif",             configurable: true,   level: "activity" },
      { name: "Budget",            configurable: true,   level: "package"  },
      { name: "Remoteness Bonus",  configurable: false,  level: "package" },
      { name: "Applicable Points", configurable: false, level: "activity" },
      { name: "Waiver",            configurable: false, level: "activity" }
    ].each do |state|
      project.states.build(state)
    end

    claimed_state = project.states.find { |s| s.name == "Claimed" }
    tarif_state = project.states.find { |s| s.name == "Tarif" }

    activity_1 = project.activities.build(
      project: project,
      name: "Vaccination", activity_states_attributes: [
        { name: "Vaccination claimed", state: claimed_state, external_reference: "cl-ext-1" },
        { name: "tarif for Vaccination ", state: tarif_state, external_reference: "tarif-ext-1" }
      ]
    )

    activity_2 = project.activities.build(
      project:                    project,
      name:                       "Clients sous traitement ARV suivi pendant les 6 premiers mois",
      activity_states_attributes: [
        {
          name:               "Clients sous traitement ARV suivi pendant les 6 premiers mois - decl",
          state:              claimed_state,
          external_reference: "cl-ext-2"
        },
        {
          name:               "tarif for Clients sous traitement ARV suivi pendant les 6 premiers mois",
          state:              tarif_state,
          external_reference: "tarif-ext-2"
        }
      ]
    )

    project.packages[0].activities = [activity_1, activity_2]
    project.packages[1].activities = [activity_1, activity_2]
    project.packages[2].activities = [activity_1, activity_2]
    project.packages[3].activities = [activity_1, activity_2]

    project.packages[0].activity_rule.decision_tables.build(content: fixture_content(:scorpio, "decision_table.csv"))

    default_quantity_states = project.states.select { |s| %w[Claimed Verified Tarif].include?(s.name) }.to_a
    default_quality_states = project.states.select { |s| ["Claimed", "Verified", "Max. Score"].include?(s.name) }.to_a
    default_performance_states = project.states.select { |s| ["Claimed", "Max. Score", "Budget"].include?(s.name) }.to_a

    suffix = ""
    update_package_with_dhis2(
      project.packages[0], suffix, default_quantity_states,
      [clinic_group],
      %w[FTRrcoaog83 P3jJH5Tu5VC FQ2o8UBlcrS M62VHgYT2n0]
    )
    update_package_with_dhis2(
      project.packages[1], suffix, default_quantity_states,
      [hospital_group],
      %w[FTRrcoaog83 P3jJH5Tu5VC FQ2o8UBlcrS M62VHgYT2n0]
    )
    update_package_with_dhis2(
      project.packages[2], suffix, default_quality_states,
      [clinic_group, hospital_group],
      %w[p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2]
    )

    update_package_with_dhis2(
      project.packages[3], suffix, default_performance_states,
      [admin_group],
      %w[p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2]
    )
    project.dump_validations
    project.save!
    project
  end

  def with_activities_and_formula_mappings(project)
      project.packages.each do |package|
        package.states.each do |state|
          package.activities.each_with_index do |activity, _index|
            activity_state = activity.activity_states.find_by(state: state)
            next if activity_state
            activity.activity_states.create!(
              state:              state,
              name:               "#{activity.name}-#{state.code}",
              external_reference: "ref--#{activity.name}-#{state.code}"
            )
          end
        end
      end

      activity_rules = project.packages.flat_map(&:rules).select(&:activity_kind?)
      activity_rules.map do |rule|
        rule.package.activities.map do |activity|
          rule.formulas.map do |formula|
            mapping = formula.find_or_build_mapping(
              activity: activity,
              kind:     rule.kind
            )
            mapping.external_reference = "#{activity.name}-#{formula.code}"
            mapping.save!
          end
        end
      end

      other_rules = []
      other_rules += project.packages.flat_map(&:rules).select(&:package_kind?)
      other_rules += project.payment_rules.flat_map(&:rule)

      other_rules.map do |rule|
        rule.formulas.map do |formula|
          mapping = formula.find_or_build_mapping(
            kind: rule.kind
          )
          mapping.external_reference = "#{rule.kind}-#{formula.code}"
          mapping.save!
        end
      end

      project.activities
             .flat_map(&:activity_states)
             .sort_by(&:name)
             .each_with_index do |as, _index|
        as.external_reference = "ref--#{as.activity.name}-#{as.state.code}"
        as.save!
      end
      self
    end

  def update_package_with_dhis2(package, suffix, states, groups, _acitivity_ids)
    package.name += suffix
    package.states = states
    groups.each_with_index do |group, index|
      package.package_entity_groups[index].assign_attributes(group)
    end
  end
end
