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
      post :create, params: { project_id: project.id, state: { name: "sample", short_name: "short_sample" } }
      expect(flash[:notice]).to eq "State created !"
      expect(project.states.where(name: "sample").first.code).to eq("sample")
      expect(project.states.where(short_name: "short_sample").first.code).to eq("sample")
    end

    it "should reject to create a state with same name" do
      post :create, params: { project_id: project.id, state: { name: "sample" } }
      expect(project.states.size).to eq(9)
      post :create, params: { project_id: project.id, state: { name: "sample" } }
      expect(project.states.size).to eq(9)
    end
  end
end
