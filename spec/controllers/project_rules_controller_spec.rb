require "rails_helper"

RSpec.describe Setup::ProjectRulesController, type: :controller do
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
    end

    let(:program) { create :program }

    let(:project) do
      project = ProjectFactory.new.build(
        dhis2_url:      "http://play.dhis2.org/demo",
        user:           "admin",
        password:       "district",
        bypass_ssl:     false,
        project_anchor: program.build_project_anchor
      )

      project.save!
      user.program = program
      user.save!
      user.reload

      project
    end

    def delete_existing_project_rules
      project.payment_rules.destroy_all
      expect(Rule.all.count).to eq(8)
    end

    describe "#new" do
      it "should render new edit form" do
        get :new, params: {
          "project_id" => project.id
        }
        expect(response).to have_http_status(200)
      end

      it "should render new form" do
        project.payment_rules.destroy_all
        get :new, params: {
          "project_id" => project.id
        }
      end
    end

    describe "#edit" do
      it "should show and edit form" do
        get :edit, params: {
          "project_id" => project.id,
          "id"         => project.payment_rules.first.id
        }
      end
    end
    describe "#update" do
      it "should reject an existing one" do
        post :update, params: {
          "project_id"   => project.id,
          "id"           => project.payment_rules.first.id,
          "payment_rule" => {
            "package_ids"     => project.packages.map(&:id).join(","),
            "rule_attributes" => {
              "id"                  => project.payment_rules.first.rule.id,
              "name"                => "payment rule",
              "formulas_attributes" => [
                { "id"          => project.payment_rules.first.rule.formulas.first.id,
                  "code"        => "value",
                  "description" => "description",
                  "expression"  => "unknown_expression_in_other_rules" }
              ]
            }
          }
        }
      end
      it "should update an existing one" do
        formula = project.payment_rules.first.rule.formulas.first
        post :update, params: {
          "project_id"   => project.id,
          "id"           => project.payment_rules.first.id,
          "payment_rule" => {
            "rule_attributes" => {
              "id"                  => project.payment_rules.first.rule.id,
              "name"                => "payment rule",
              "formulas_attributes" => [
                { "id"          => formula.id,
                  "code"        => formula.code,
                  "description" => "description",
                  "expression"  => "#{formula.expression} * 2 " }
              ]
            }
          }
        }
        expect(response).to redirect_to("/")
      end
    end

    describe "#create" do
      it "should create a payment rule" do
        project.id
        rule_count_before = Rule.all.count
        payment_rule_count_before = PaymentRule.all.count
        post :create, params: {
          "project_id"   => project.id,
          "payment_rule" => {
            "package_ids"     => project.packages.map(&:id),
            "rule_attributes" => {
              "name"                => "payment rule",
              "formulas_attributes" => [
                { "code"        => "value",
                  "description" => "description",
                  "expression"  => "quality_technical_score_value" }
              ]
            }
          }
        }
        expect(Rule.all.count).to eq rule_count_before + 1
        expect(PaymentRule.all.count).to eq payment_rule_count_before + 1
      end

      it "should not create when invalid expression" do
        delete_existing_project_rules
        post :create, params: {
          "project_id"   => project.id,
          "package_ids"  => project.packages.map(&:id),
          "payment_rule" => {
            "rule_attributes" => {
              "name"                => "payment rule",
              "formulas_attributes" => [
                { "code"        => "value",
                  "description" => "description",
                  "expression"  => "invalid_state_or_expression" }
              ]
            }
          }
        }

        expect(Rule.all.count).to eq 8
      end
    end
  end
end
