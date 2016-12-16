# == Schema Information
#
# Table name: formulas
#
#  id          :integer          not null, primary key
#  code        :string           not null
#  description :string           not null
#  expression  :text             not null
#  rule_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require "rails_helper"

RSpec.describe Formula, type: :model do

  def new_formula(args)
    rule = Rule.new
    Formula.new(args.merge(code: args[:code] || "sample_expression", description: "description", rule: rule))
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
      expect(formula.errors.full_messages).to eq(["Code : should only contains small letters and _ like 'quality_score' or 'total_amount'"])
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

    it "should validate formula for SUM expression" do
      pending("need to fix this one since now dependends on package activity_rule")
      formula = new_formula(expression: "SUM(%{amount_values})")

      formula.valid?
      expect(formula.errors[:expression]).to eq([])
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
  end
end
