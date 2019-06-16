# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::RulesController, type: :controller do
  include_context "basic_context"

  describe "When non authenticated #new" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1, package_id: 2 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    before(:each) do
      sign_in user
    end

    let(:program) { create :program }

    let(:project) do
      project = full_project

      project.save!
      user.program = program
      user.save!
      user.reload

      project
    end

    let(:package) { project.packages.first }

    def delete_existing_project_rules
      project.payment_rules.destroy_all
      expect(Rule.all.count).to eq(8)
    end

    describe "#new" do
      it "should render new edit form" do
        get :new, params: {
          "package_id" => package.id,
          "project_id" => project.id
        }
        expect(response).to have_http_status(200)
      end

      it "should render new form" do
        project.payment_rules.destroy_all
        get :new, params: {
          "project_id" => project.id,
          "package_id" => package.id
        }
      end
    end

    describe "#create" do
      it "should create a rule with formula and decision table" do
        post :create, params: {
          "package_id" => package.id,
          "project_id" => project.id,
          rule: {
            name:                "sample rule",
            kind:                "zone",
            formulas_attributes: [
              {
                code:        "zone_formula",
                short_name:  "short",
                expression:  "4 +5",
                description: "pma for the zone"
              }
            ]
          }
        }
        expect(flash[:notice]).to eq("Rule created !")
        expect(response).to redirect_to("/")
        expect(Rule.last.name).to eq("sample rule")
      end

      it "should render new form" do
        project.payment_rules.destroy_all
        post :create, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          rule: { name: nil, kind: "activity" }
        }
        expect(assigns(:rule).valid?).to eq(false)
        expect(response).to have_http_status(200)
        expect(response.body).to include("Name can&#39;t be blank ")
      end
    end

    describe "#edit" do
      it "should show and edit form" do
        get :edit, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          "id"         => package.activity_rule.id
        }
      end
    end

    describe "#update" do
      it "should validate and render errors" do
        post :update, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          id: package.activity_rule.id,
          rule: { name: nil, kind: "multi-entities" }
        }
        expect(assigns(:rule).valid?).to eq(false)
        expect(response).to have_http_status(200)
        expect(response.body).to include("Name can&#39;t be blank ")
      end

      it "should update" do
        post :update, params: {
          "package_id" => package.id,
            "project_id" => project.id,
            id: package.activity_rule.id,
            rule: {
              name: "sample rule 2"
            }
        }
        expect(flash[:notice]).to eq("Rule updated !")
        package.activity_rule.reload
        expect(package.activity_rule.name).to eq("sample rule 2")
      end
    end
  end

  describe "When new engine and authenticated" do
    before(:each) do
      sign_in user
    end

    let(:program) { create :program }

    let(:project) do
      project = full_project
      project.engine_version = 3
      project.save!
      user.program = program
      user.save!
      user.reload

      project
    end

    let(:package) {
      package = project.packages.first
      package.update!(kind: "zone")
      package
    }

    describe "zone rules for non-zone packages" do
      before do
        package.update!(kind: "single")
      end

      %w[zone zone_activity].each do |kind|
        it "can't visit the new page not-allowed: #{kind}" do
          get :new, params: {
            "project_id" => project.id,
                "package_id" => package.id,
                kind: kind
          }
          expect(response.request.flash["alert"]).to_not be_empty
          expect(response).to redirect_to(root_path)
        end

        it "can't create a not allowed: #{kind} rule" do
          post :create, params: {
            "project_id" => project.id,
                 "package_id" => package.id,
                 kind: kind,
                 rule: { name: "Does not matter" }
          }
          expect(response.request.flash["alert"]).to_not be_empty
          expect(response).to redirect_to(root_path)
        end
      end
    end

    describe "#create zone rule" do
      it "display form to create a " do
        get :new, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          kind:                "zone"
        }
      end

      it "allow the creation of zone rules referencing package formulas values" do
        post :create, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          kind:                "zone",
          rule: {
            name:                "zone",
            kind:                "zone",
            formulas_attributes: [{
              code:        "zone_formula",
              short_name:  "short",
              expression:  "sum(%{quantity_total_pma_values})",
              description: "pma for the zone"
            }]
          }
        }
        rule = assigns(:rule)
        expect(rule.valid?).to eq(true)
        expect(response).to have_http_status(302)
        zone_formula = rule.formulas.first
        expect(zone_formula.code).to eq("zone_formula")
        expect(zone_formula.id).not_to be_nil
        expect(zone_formula.short_name).to eq("short")
      end
    end

    describe "#create activity_zone rule" do
      it "display form to create a " do
        get :new, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          kind:                "zone_activity"
        }
      end

      it "allow the creation of zone_activity rules referencing activity_rule formulas values" do
        activity_rule = package.activity_rule
        variable_used_in_activity_rule = activity_rule.formulas.first.code
        post :create, params: {
          "project_id" => project.id,
          "package_id" => package.id,
          kind:                "zone_activity",
          rule: {
            name:                "Zone Activity Rule",
            kind:                "zone_activity",
            formulas_attributes: [{
              code:        "za_formula",
              short_name:  "short za",
              expression:  "sum(%{#{variable_used_in_activity_rule}_values})",
              description: "zone activity rule"
            }]
          }
        }
        rule = assigns(:rule)
        expect(rule.valid?).to eq(true)
        expect(response).to have_http_status(302)
        zone_formula = rule.formulas.first
        expect(zone_formula.code).to eq("za_formula")
        expect(zone_formula.id).not_to be_nil
        expect(zone_formula.short_name).to eq("short za")
      end
    end
  end
end
