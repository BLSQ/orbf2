require "rails_helper"

RSpec.describe SetupController, type: :controller do
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

    it "should display steps" do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:steps).size).to eq 6
    end
  end
end
