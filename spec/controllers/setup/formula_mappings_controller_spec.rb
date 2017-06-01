require "rails_helper"

RSpec.describe Setup::FormulaMappingsController, type: :controller do
  describe "When non authenticated #orgunitgroup" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  let(:program) { create :program }

  let(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program
    project
  end

  describe "When authenticated" do
    include_context "basic_context"

    before(:each) do
      sign_in user
    end

    it "should display an edit screen" do
      get :new, params: { project_id: project.id }
      counts_by_kind = assigns(:formula_mappings).mappings.each_with_object(Hash.new(0)) { |e, h| h[e.kind] += 1 }

      expect(counts_by_kind).to eq("activity" => 24, "package" => 9, "payment" => 6)
      expect(assigns(:formula_mappings).project).to eq project
    end

    #  id                 :integer          not null, primary key
    #  formula_id         :integer          not null
    #  activity_id        :integer
    #  external_reference :string           not null
    #  kind               :string           not null

    it "should create formula_mappings" do
      get :new, params: { project_id: project.id }
      built = assigns(:formula_mappings).mappings.find { |mapping| mapping.external_reference.blank? }
      before = FormulaMapping.count

      post :create, params: {
        project_id:       project.id,
        formula_mappings: [
          {
            formula_id:         built.formula_id,
            activity_id:        built.activity_id,
            external_reference: "new-external_reference",
            kind:               built.kind
          }
        ]
      }

      after = FormulaMapping.count
      expect(after).to eq before + 1
    end

    it "should delete form" do
      get :new, params: { project_id: project.id }
      existing = assigns(:formula_mappings).mappings.find { |mapping| mapping.external_reference.present? }
      before = FormulaMapping.count
      post :create, params: {
        project_id:       project.id,
        formula_mappings: [
          { id:         existing.id,
            formula_id: existing.formula_id,
            kind:       existing.kind,
            external_reference: "" }
        ]
      }

      after = FormulaMapping.count
      expect(after).to eq(before - 1)
    end
  end
end
