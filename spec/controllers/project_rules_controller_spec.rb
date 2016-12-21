require "rails_helper"

RSpec.describe ProjectRulesController, type: :controller do
  include_context "basic_context"

  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    before(:each) do
      sign_in user
      states
    end

    let(:project) do
      user.project = ProjectFactory.new.build(dhis2_url: "http://play.dhis2.org/demo", user: "admin", password: "district", bypass_ssl: false)
      user.save!
      user.project
    end

    def delete_existing_project_rules
      project.rules.destroy_all
      expect(Rule.all.count).to eq(6)
    end

    describe "#create" do
      it "should create a payment rule" do
            post :create, params: {
          "project_id" => project.id,
          "rule"       => {
            "name"                => "payment rule",
            "formulas_attributes" => [
              { "code"        => "value",
                "description" => "description",
                "expression"  => "quality_technical_score_value" }
            ]
          }
        }
        expect(Rule.all.count).to eq 7
      end

      it "should not create an existing one" do
        post :create, params: {
          "project_id" => project.id,
          "rule"       => {
            "name"                => "payment rule",
            "formulas_attributes" => [
              { "code"        => "value",
                "description" => "description",
                "expression"  => "quality_technical_score_value" }
            ]
          }
        }
        expect(flash[:alert]).to eq "Sorry you can't create a new payment rule, edit existing one."
        expect(response).to redirect_to("/")
      end

      it "should not create when invalid expression" do
        delete_existing_project_rules
        post :create, params: {
          "project_id" => project.id,
          "rule"       => {
            "name"                => "payment rule",
            "formulas_attributes" => [
              { "code"        => "value",
                "description" => "description",
                "expression"  => "invalid_state_or_expression" }
            ]
          }
        }

        expect(Rule.all.count).to eq 6
      end
    end
  end
end
