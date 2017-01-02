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

    describe "#new" do
      it "should render new edit form" do
        get :new, params: {
          "project_id" => project.id
        }
        expect(response).to redirect_to("/")
      end
      it "should render new edit form" do
        project.payment_rule.destroy
        get :new, params: {
          "project_id" => project.id
        }
      end
    end

    describe "#edit" do
      it "should show and edit form" do
        get :edit, params: {
          "project_id" => project.id,
          "id"         => project.payment_rule.id
        }
      end
    end
    describe "#update" do
      it "should reject an existing one" do
        post :update, params: {
          "project_id" => project.id,
          "id"         => project.payment_rule.id,
          "rule"       => {
            "name"                => "payment rule",
            "formulas_attributes" => [
              { "id"          => project.payment_rule.formulas.first.id,
                "code"        => "value",
                "description" => "description",
                "expression"  => "unknown_expression_in_other_rules" }
            ]
          }
        }
      end
      it "should update an existing one" do
        formula = project.payment_rule.formulas.first
        post :update, params: {
          "project_id" => project.id,
          "id"         => project.payment_rule.id,
          "rule"       => {
            "name"                => "payment rule",
            "formulas_attributes" => [
              { "id"          => formula.id,
                "code"        => formula.code,
                "description" => "description",
                "expression"  => "#{formula.expression} * 2 " }
            ]
          }
        }
        expect(response).to redirect_to("/")
      end
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
