
require "rails_helper"

RSpec.describe Rules::CalculatorFactory, type: :services do
  describe "custom functions" do
    let(:calculator) { Rules::CalculatorFactory.new.new_calculator }

    it "should support safe_div function" do
      expect(calculator.evaluate("safe_div(10,0)")).to eq(0)
      expect(calculator.evaluate("safe_div(5,10)")).to eq(0.5)
    end

    it "should support sum function" do
      expect(calculator.evaluate("sum(10,20,30)")).to eq(60)
      expect(calculator.evaluate("sum(0.5,1.5,2.3)")).to eq(4.3)
    end

    it "should support avg function" do
      expect(calculator.evaluate("avg(10,20,30)")).to eq(20.0)
      expect(calculator.evaluate("avg(10)")).to eq(10.0)
      expect(calculator.evaluate("avg(0.5,1.5,2.3)")).to be_within(0.00000001).of(1.433333333)
    end

    it "should support score_table function" do
      expect(calculator.evaluate("score_table(10, 0,10,0, 10,20,1, 20,30,2)")).to eq(1)
      expect(calculator.evaluate("score_table(20, 0,10,0, 10,20,1, 20,30,2)")).to eq(2)
      expect(calculator.evaluate("score_table(45, 0,10,0, 10,20,1, 20,30,2,10)")).to eq(10)
    end

    it "should support access function" do
      expect(calculator.evaluate("access(1,2,3,4 , -1)")).to eq(4)
      expect(calculator.evaluate("access(1,2,3,4 , 0)")).to eq(1)
      expect(calculator.evaluate("access(1,2,3,4 , 1)")).to eq(2)
      expect(calculator.evaluate("access(1,2,3,4 , 2)")).to eq(3)
      expect(calculator.evaluate("access(1,2,3,4 , 3)")).to eq(4)
    end
  end
end
