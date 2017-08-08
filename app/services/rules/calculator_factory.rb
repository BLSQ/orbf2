require "dentaku"
require "dentaku/calculator"

module Rules
  class CalculatorFactory
    SCORE_TABLE = lambda do |*args|
      target = args.shift
      args.each_slice(3).find do |lower, greater, result|
        greater.nil? || result.nil? ? true : lower <= target && target < greater
      end.last
    end

    SAFE_DIV = lambda do |*args|
      dividend = args[0]
      divisor = args[1]
      divisor > 0 ? (dividend.to_f / divisor.to_f) : 0
    end

    ACCESS = lambda do |*args|
      array = args[0..-2]
      index = args[-1]
      array[index]
    end

    SUM = lambda do |*args|
      args.inject(0.0) { |sum, x| sum + x }
    end

    AVG = lambda do |*args|
      args.inject(0.0) { |sum, el| sum + el } / args.size
    end

    BETWEEN = ->(lower, score, greater) { lower <= score && score <= greater }

    def new_calculator
      calculator = Dentaku::Calculator.new
      calculator.add_function(:between, :logical, BETWEEN)
      calculator.add_function(:abs, :number, ->(number) { number.abs })
      calculator.add_function(:score_table, :numeric, SCORE_TABLE)
      calculator.add_function(:avg, :numeric, AVG)
      calculator.add_function(:sum, :numeric, SUM)
      calculator.add_function(:safe_div, :numeric, SAFE_DIV)
      calculator.add_function(:access, :numeric, ACCESS)
      calculator
   end
  end
end
