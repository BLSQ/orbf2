require "rails_helper"

RSpec.describe MainEntityGroupsController, type: :controller do
  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      post :create, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #create" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:project) do
      project = create :project
      user.project = project
      user.save!
      user.reload
      project
    end

    let(:valid_attributes) do
      {
        project_id:   project.id,
        entity_group: {
          external_reference: "external_reference",
          name:               "entity_group_name"
        }
      }
    end

    it "should verify that a project already exist" do
      post :create, params: {
        project_id:   1,
        entity_group: {
          external_reference: "external_reference",
          name:               "entity_group_name"
        }
      }

      expect(response).to redirect_to("/")
      expect(flash[:alert]).to eq("Please configure your dhis2 settings first !")
    end

    it "should create missing entity group when correct info provided" do
      post :create, params: valid_attributes

      expect(response).to redirect_to("/")
      expect(flash[:success]).to eq("Main entity group set !")
      group_entry = EntityGroup.all.last
      expect(group_entry.external_reference).to eq("external_reference")
      expect(group_entry.name).to eq("entity_group_name")
    end

    it "should update when correct info provided" do
      post :create, params: valid_attributes
      post :create, params: valid_attributes.merge(entity_group: {
                                                     external_reference: "new_external_reference",
                                                     name:               "new_entity_group_name"
                                                   })
      expect(response).to redirect_to("/")
      expect(flash[:success]).to eq("Main entity group set !")

      group_entry = EntityGroup.all.last
      expect(group_entry.external_reference).to eq("new_external_reference")
      expect(group_entry.name).to eq("new_entity_group_name")
    end

    it "should validate presence" do
      post :create, params: valid_attributes.merge(
        entity_group: {
          external_reference: " ",
          name:               ""
        }
      )
      expect(response).to redirect_to("/")
      expect(flash[:alert]).to eq("External reference can't be blank, Name can't be blank")
    end
  end
end
