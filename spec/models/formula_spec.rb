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
#  frequency   :string
#

require "rails_helper"

RSpec.describe Formula, type: :model do
  it "enables paper trail" do
    is_expected.to be_versioned
  end

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
      expect(formula.errors.full_messages).to eq(["Code : should only contains lowercase letters and _ like 'quality_score' or 'total_amount' vs upperCase"])
    end
  end

  describe "frequency validation" do 
    it "should allow empty frequency" do 
      formula = new_formula(frequency: "", expression: "variable - 456")
      formula.frequency=""
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
  end
end
