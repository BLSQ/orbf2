require "rails_helper"

RSpec.describe Setup::StatesController, type: :controller do
  describe "When non authenticated #create" do
    it "should redirect to sign on" do
      post :create, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated #index" do
    include_context "basic_context"
    before(:each) do
      sign_in user
    end

    let(:project) { full_project }

    it "should allow to create a new project's state" do
      get :new, params: { project_id: project.id }
    end

    it "should allow to create a new project's state" do
      post :create, params: { project_id: project.id, state: { name: "Maximum Score", short_name: "Max Score" } }
      expect(flash[:notice]).to eq "State created !"
      project.reload
      last_created_state = project.states.last
      expect(last_created_state.name).to eq("Maximum Score")
      expect(last_created_state.code).to eq("maximum_score")
      expect(last_created_state.short_name).to eq("Max Score")
    end

    it "should reject to create a state with same name" do
      post :create, params: { project_id: project.id, state: { name: "sample" } }
      expect(project.states.size).to eq(9)
      post :create, params: { project_id: project.id, state: { name: "sample" } }
      expect(project.states.size).to eq(9)
    end
  end
end
