require "rails_helper"

RSpec.describe "Rules Engine" do
  # The reason this spec is here, is to avoid deploying a version of
  # ORBF2 with a mismatched version of hesabu.
  #
  # Since `hesabu`, `go-hesabu` and `orbf-rules_engine` have
  # dependencies on each other, and are very much in active
  # development, it does not always make sense to cut a new version of
  # each gem. So that's why in the Gemfile we're using git versions.
  #
  # By using one of the newer features we can make sure that the whole
  # pipeline: `orfb-rules_engine -> hesabu -> go-hesabu` works.
  describe 'can use newish features' do
    {
      "version 3" => Orbf::RulesEngine::CalculatorFactory.build(3),
      "version 2" => Orbf::RulesEngine::CalculatorFactory.build(2),
      "internal" => Rules::CalculatorFactory.new.new_calculator
    }.each do |name, calculator|
      it ".eval_array (#{name})" do
        solution = calculator.solve(
          "arr" => "array(1,2,-3,4,5)",
          "evaled_arr" => "eval_array('a', arr, 'b', arr, 'a - b')",
          "result" => "sum(evaled_arr)"
        )
        expect(solution["result"]).to eq(0.0)
      end
    end
  end
end