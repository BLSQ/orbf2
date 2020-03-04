# frozen_string_literal: true
# == Schema Information
#
# Table name: formulas
#
#  id                      :bigint(8)        not null, primary key
#  code                    :string           not null
#  description             :string           not null
#  exportable_formula_code :string
#  expression              :text             not null
#  frequency               :string
#  short_name              :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  rule_id                 :integer
#
# Indexes
#
#  index_formulas_on_rule_id  (rule_id)
#
# Foreign Keys
#
#  fk_rails_...  (rule_id => rules.id)
#

require "rails_helper"

RSpec.describe Formula, type: :model do
  it "enables paper trail" do
    is_expected.to be_versioned
  end

  let(:project) {
    Project.new(engine_version: 3)
  }
  let(:package){
    project.packages.build
  }
  let(:rule){
    Rule.new(name:"rspec",kind: "activity", package: package)
  }
  def new_formula(args)
    rule.formulas.build(
      args.merge(
        code:        args[:code] || "sample_expression",
        description: "description",
        rule:        rule
      )
    )
  end

  describe "Code validation" do
    it "should accept snake_case" do
      formula = new_formula(code: "snake_case", expression: "45")
      formula.valid?
      expect(formula.errors.full_messages).to eq([])
    end

    it "should reject upperCase" do
      formula = new_formula(code: "upperCase", expression: "45", description: "description")
      formula.valid?
      expect(formula.errors.full_messages).to eq(["Code : should only contains lowercase letters and _ (no space, no upper letter) like 'quality_score' or 'total_amount' (NOT upperCase)"])
    end
  end

  describe "frequency validation" do
    it "should allow empty frequency" do
      formula = new_formula(frequency: "", expression: "variable - 456")
      formula.frequency = ""
      expect(formula.valid?).to be true
      expect(formula.frequency).to be nil
    end
  end

  describe "Expression validation" do
    it "should accept activity expression" do
      formula = new_formula(expression: "variable - 456")
      expect(formula.valid?).to be true
    end

    it "should reject formula activity expression bad if" do
      formula = new_formula(expression: "IF (bad_if_statement - 456")
      formula.valid?
      expect(formula.errors[:expression]).to eq(["too many opening parentheses"])
    end

    it "should reject formula activity expression unknown function" do
      formula = new_formula(expression: "unknown(bad_if_statement - 456)")
      formula.valid?
      expect(formula.errors[:expression]).to eq(["Undefined function unknown"])
    end

    it "should reject dangerous expression" do
      formula = new_formula(expression: "`ls -als`")

      formula.valid?
      expect(formula.errors[:expression]).to eq(["parse error at: '`ls -als`'"])
    end

    it "should reject bad formatted expression" do
      formula = new_formula(expression: "dsfsdf %[{{")

      formula.valid?
      expect(formula.errors[:expression]).to eq(["malformed format string - %["])
    end

    it "propose appropriate %{..._values}" do
      formula = new_formula(expression: 'eval_array( "is_nul", array(%{active_is_null_last_3_months_window_values}) , "hard_coded", array(1,2,3), "is_nul")')
      formula.rule.package.project.engine_version = 3
      package.frequency = "monthly"
      state = project.states.build(name: "active")
      package.package_states.build(state: state)

      expect(formula.rule.available_variables_for_values).to include("active_is_null_last_3_months_window_values")
      expect(formula.rule.formulas_are_coherent).to be_truthy
      expect(formula.rule.errors[:formulas]).to eq([])
    end
  end

  describe "exportable_formula_code validation" do
    it "reject reference to non existing formula" do
      formula = new_formula(expression: "1", exportable_formula_code: "unknown")
      formula.rule.formulas.build(code: "sample_exportable")

      formula.valid?
      expect(formula.errors[:exportable_formula_code]).to eq(["the exportable formula code reference an incorrect code (unknown) should be one of : sample_exportable"])
    end
  end
end
