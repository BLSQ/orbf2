require "rails_helper"

RSpec.describe Setup::ActivitiesController, type: :controller do
  describe "When non authenticated #orgunitgroup" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    include_context "basic_context"

    before(:each) do
      sign_in user
    end

    let!(:project) { full_project }

    it "should return form for creation of a new activity" do
      get :new, params: { project_id: project.id }
      activity = assigns(:activity)
      expect(activity).not_to be_nil
    end

    it "should return form for creation of a new activity" do
      get :edit, params: { project_id: project.id, id: project.activities.first.id }
      activity = assigns(:activity)
      states = assigns(:states)
      expect(states.map(&:code)).to eq %w[claimed verified validated max_score tarif applicable_points waiver]
      expect(activity).to eq project.activities.first
    end

    it "should be possible to create 2 activity constant" do
      state_id_1 = project.states.first.id
      state_id_2 = project.states.second.id

      post :create, params: {
        project_id: project.id,
        activity:   {
          name:                       "activity_name",
          activity_states_attributes: [
            {
              name:               "activity_state_name",
              external_reference: "",
              kind:               "formula",
              formula:            "1",
              state_id:           state_id_1
            },
            {
              name:               "activity_state_name",
              external_reference: "",
              kind:               "formula",
              formula:            "1",
              state_id:           state_id_2
            }
          ]
        }
      }
      project.activities.reload
    end

    it "should be possible to create a data element activity" do
      post :create, params: {
        project_id: project.id,
        activity:   {
          name:                       "activity_name",
          activity_states_attributes: [
            {
              name:               "activity_state_name",
              external_reference: "external_reference",
              kind:               "data_element"
            }
          ]
        }
      }
    end

    it "should be possible to create a indicator activity state" do
      post :create, params: {
        project_id: project.id,
        activity:   {
          name:                       "activity_name",
          activity_states_attributes: [
            {
              name:               "activity_state_name",
              external_reference: "external_reference",
              kind:               "indicator"
            }
          ]
        }
      }
    end
  end
end
