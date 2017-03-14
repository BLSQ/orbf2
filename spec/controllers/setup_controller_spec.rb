require "rails_helper"

RSpec.describe Setup::SetupController, type: :controller do
  describe "When non authenticated #index" do
    it "should redirect to sign on" do
      get :index
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    it "should display steps when Dhis2 not set" do
      get :index
      expect(response).to have_http_status(:success)
      expect(setup.steps.size).to eq 8
      expect(setup.steps.all?(&:todo?)).to eq true
    end

    let(:program) do
      create :program
    end

    let(:project) do
      project = create :project, project_anchor: program.build_project_anchor
      user.program = program
      user.save!
      user.reload
      project
    end

    def setup
      assigns(:setup)
    end

    def dump_steps_for_debugs
      puts setup.steps.map(&:inspect)
    end

    it "should display main entity group when Dhis2 is complete" do
      project
      get :index, project_id: project.id
      expect(response).to have_http_status(:success)
      expect(setup.steps.map(&:todo?)).to eq [false, true, true, true, true, true, true, true]
    end

    it "should display packages group when main entity group" do
      project
      project.create_entity_group(external_reference: "external_reference", name: "main group")

      get :index, project_id: project.id
      expect(response).to have_http_status(:success)
      expect(setup.steps.map(&:todo?)).to eq [false, false, true, true, true, true, true, true]
    end

    it "should display rules group packages exist" do
      project
      project.create_entity_group(external_reference: "external_reference", name: "main group")
      package = project.packages.create!(
        data_element_group_ext_ref: "data_element_group_ext_ref",
        name:                       "main group",
        frequency:                  "monthly"
      )
      package.package_entity_groups.create!(
        name:                            "Entity 1 name",
        organisation_unit_group_ext_ref: "organisation_unit_group_ext_ref"
      )

      get :index, project_id: project.id
      expect(response).to have_http_status(:success)
      expect(setup.steps.map(&:todo?)).to eq [false, false, true, true, true, true, true, true]
    end
  end
end
