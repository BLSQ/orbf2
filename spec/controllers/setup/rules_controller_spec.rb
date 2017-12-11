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
            name: "sample rule"
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
          rule: { name: nil, kind: nil }
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
        expect(response).to redirect_to("/")
        package.activity_rule.reload
        expect(package.activity_rule.name).to eq("sample rule 2")
      end
    end
  end
end
