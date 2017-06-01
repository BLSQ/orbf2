require "rails_helper"

RSpec.describe Setup::IncentivesController, type: :controller do
  describe "When non authenticated #new" do
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

    let(:program) { create :program }

    let(:project) do
      project = full_project
      project.save!
      user.save!
      user.program = program
      project
    end

    describe "#new" do
      it "should display a form for current project with a few default" do
        get :new, params: { project_id: project.id }
        incentives = assigns(:incentive)

        expect(incentives.project.id).to eq(project.id)
        expect(incentives.start_date).not_to be_nil
        expect(incentives.end_date).not_to be_nil
        expect(incentives.state_id).not_to be_nil
      end
    end
  end
end
