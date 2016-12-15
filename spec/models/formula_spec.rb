# == Schema Information
#
# Table name: formulas
#
#  id          :integer          not null, primary key
#  code        :string           not null
#  description :string           not null
#  expression  :text             not null
#  rules_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require "rails_helper"

RSpec.describe Formula, type: :model do

  describe "Code validation" do
    it "should accept snake_case" do
      formula = Formula.new(code: "snake_case", expression: "45")
      formula.valid?
      expect(formula.errors.full_messages).to eq([])
    end

    it "should reject upperCase" do
      formula = Formula.new(code: "upperCase", expression: "45")
      formula.valid?
      expect(formula.errors.full_messages).to eq(["Code : should only contains small letters and _ like 'quality_score' or 'total_amount'"])
    end
  end

  describe "Expression validation" do
    it "should accept activity expression" do
      formula = Formula.new(code: "sample_expression", expression: "variable - 456")
      expect(formula.valid?).to be true
    end

    it "should reject formula activity expression bad if" do
      formula = Formula.new(code: "sample_expression", expression: "IF (bad_if_statement - 456")
      formula.valid?
      expect(formula.errors[:expression]).to eq(["too many opening parentheses"])
    end

    it "should reject formula activity expression unknown function" do
      formula = Formula.new(code: "sample_expression", expression: "unknown(bad_if_statement - 456)")
      formula.valid?
      expect(formula.errors[:expression]).to eq(["Undefined function unknown"])
    end

    it "should validate formula for SUM expression" do
      formula = Formula.new(code: "sample_expression", expression: "SUM(%{amount_values})")

      formula.valid?
      expect(formula.errors[:expression]).to eq([])
    end

    it "should reject dangerous expression" do
      formula = Formula.new(code: "sample_expression", expression: '`ls -als`')

      formula.valid?
      expect(formula.errors[:expression]).to eq(["parse error at: '`ls -als`'"])
    end
  end
end
