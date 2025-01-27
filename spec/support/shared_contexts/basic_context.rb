shared_context "basic_context" do
  let(:program) do
    create :program, code: "siera"
  end
  let!(:user) do
    FactoryBot.create(:user, program: program)
  end

  let(:full_project) do
    project_factory = ProjectFactory.new
    project = project_factory.build(
      dhis2_url:      "http://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: program.build_project_anchor,
      invoice_app_path: "/api/apps/ORBF2-test-factures/test.html"
    )
    project_factory.update_links(project)

    project.dump_validations

    # We need to force a load of the code of an activity, so it will
    # get saved to the DB, since a package will now use them sorted by
    # code (to avoid non-deterministic iteration)
    project.activities.each { |a| a.code }

    project.save!
    project
  end

  def stub_dhis2_lookups(project)
    stub_request(:post, "#{project.dhis2_url}/api/metadata")
    .with(body: "{\"dataElementGroups\":[{\"name\":\"azeaze\",\"shortName\":\"azeaze\",\"code\":\"azeaze\",\"dataElements\":[{\"id\":\"FTRrcoaog83\"}]}]}")
    .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))

    stub_request(:get, "#{project.dhis2_url}/api/dataElementGroups?fields=:all&filter=name:eq:azeaze")
      .to_return(status: 200, body: fixture_content(:dhis2, "data_element_group.json"))

    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&filter=id:in:%5Bentityid1%5D&pageSize=1")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))

    stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroupSets?fields=:all&filter=id:in:%groupsets_ext_ref1,groupsets_ext_ref2%5D&pageSize=1")
      .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))
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
end
