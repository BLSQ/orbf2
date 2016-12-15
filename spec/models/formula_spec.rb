require "rails_helper"

RSpec.describe Formula, type: :model do
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
  end
end
