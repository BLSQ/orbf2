# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::PackagesController, type: :controller do
  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"

    before(:each) do
      sign_in user
    end
    let(:program) do
      create :program
    end
    let(:project) do
      project = build :project
      %w[claimed declared tarif].each do |state_name|
        project.states.build(name: state_name)
      end
      project.project_anchor = program.build_project_anchor
      project.save!
      user.program = program
      user.save!
      user.reload
      project.create_entity_group(external_reference: "external_reference", name: "main group")
      project
    end

    it "should display a form for editing" do
      project

      get :new, params: { project_id: project.id }
    end

    it "should create a package based on params with main entity groups without target entity groups" do
      project

      state_ids = project.states.map(&:id).map(&:to_s).slice(0, 3)
      expect(state_ids.size).to eql 3
      stub_request(:post, "#{project.dhis2_url}/api/metadata")
        .with(body: "{\"dataElementGroups\":[{\"name\":\"azeaze\",\"shortName\":\"azeaze\",\"code\":\"azeaze\",\"dataElements\":[{\"id\":\"FTRrcoaog83\"}]}]}")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))

      stub_request(:get, "#{project.dhis2_url}/api/dataElementGroups?fields=:all&filter=name:eq:azeaze")
        .to_return(status: 200, body: fixture_content(:dhis2, "data_element_group.json"))

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&filter=id:in:%5Bentityid1%5D&pageSize=1")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroupSets?fields=:all&filter=id:in:%groupsets_ext_ref1,groupsets_ext_ref2%5D&pageSize=1")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))

      post :create, params: {
        "project_id"    => project.id,
        "data_elements" => { project.state(:tarif).id.to_s => { external_reference: "FTRrcoaog83" } },
        "package"       => {
          "name"                 => "azeaze",
          "state_ids"            => state_ids,
          "frequency"            => "monthly",
          "main_entity_groups"   => ["entityid1"],
          "target_entity_groups" => [],
          "groupsets_ext_refs"   => %w[groupsets_ext_ref1 groupsets_ext_ref2]
        }
      }

      package = assigns(:package)

      groups_set_refs = %w[sample_groupset_ext other_groupset_ext]

      post :update, params: {
        "project_id"    => project.id,
        "id"            => package.id,
        "data_elements" => { project.state(:tarif).id.to_s => { external_reference: "FTRrcoaog83" } },
        "package"       => {
          "name"                 => "new name",
          "state_ids"            => state_ids.slice(0, 2),
          "frequency"            => "monthly",
          "main_entity_groups"   => ["entityid1"],
          "target_entity_groups" => [],
          "groupsets_ext_refs"   => groups_set_refs
        }
      }

      package.reload
      expect(package.groupsets_ext_refs).to eq(groups_set_refs)
      expect(package.main_entity_groups.map(&:organisation_unit_group_ext_ref)).to eq(["entityid1"])
      expect(package.target_entity_groups.map(&:organisation_unit_group_ext_ref)).to eq([])
    end

    it "should create a package based on params with main entity groups and target entity groups" do
      project

      state_ids = project.states.map(&:id).map(&:to_s).slice(0, 3)
      expect(state_ids.size).to eql 3
      stub_request(:post, "#{project.dhis2_url}/api/metadata")
        .with(body: "{\"dataElementGroups\":[{\"name\":\"azeaze\",\"shortName\":\"azeaze\",\"code\":\"azeaze\",\"dataElements\":[{\"id\":\"FTRrcoaog83\"}]}]}")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups.json"))

      stub_request(:get, "#{project.dhis2_url}/api/dataElementGroups?fields=:all&filter=name:eq:azeaze")
        .to_return(status: 200, body: fixture_content(:dhis2, "data_element_group.json"))

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroups?fields=:all&filter=id:in:%5Bentityid1,sub_entityid1%5D&pageSize=2")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid-with-target.json"))

      stub_request(:get, "#{project.dhis2_url}/api/organisationUnitGroupSets?fields=:all&filter=id:in:%groupsets_ext_ref1,groupsets_ext_ref2%5D&pageSize=1")
        .to_return(status: 200, body: fixture_content(:dhis2, "organisationUnitGroups-byid.json"))

      post :create, params: {
        "project_id"    => project.id,
        "data_elements" => { project.state(:tarif).id.to_s => { external_reference: "FTRrcoaog83" } },
        "package"       => {
          "name"                 => "azeaze",
          "state_ids"            => state_ids,
          "frequency"            => "monthly",
          "main_entity_groups"   => ["entityid1"],
          "target_entity_groups" => ["sub_entityid1"],
          "groupsets_ext_refs"   => %w[groupsets_ext_ref1 groupsets_ext_ref2],
          "include_main_orgunit" => true
        }
      }

      package = assigns(:package)
      expect(package.include_main_orgunit).to eq(true)

      groups_set_refs = %w[sample_groupset_ext other_groupset_ext]

      post :update, params: {
        "project_id"    => project.id,
        "id"            => package.id,
        "data_elements" => { project.state(:tarif).id.to_s => { external_reference: "FTRrcoaog83" } },
        "package"       => {
          "name"                 => "new name",
          "state_ids"            => state_ids.slice(0, 2),
          "frequency"            => "monthly",
          "main_entity_groups"   => ["entityid1"],
          "target_entity_groups" => ["sub_entityid1"],
          "groupsets_ext_refs"   => groups_set_refs,
          "include_main_orgunit" => false
        }
      }

      package.reload
      expect(package.include_main_orgunit).to eq(false)
      expect(package.groupsets_ext_refs).to eq(groups_set_refs)
      expect(package.main_entity_groups.map(&:organisation_unit_group_ext_ref)).to eq(["entityid1"])
      expect(package.target_entity_groups.map(&:organisation_unit_group_ext_ref)).to eq(["sub_entityid1"])
    end
  end
end
