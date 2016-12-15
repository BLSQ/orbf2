require "dentaku"
require "dentaku/calculator"

module Rules
  class Solver

    def initialize
      @@calculator ||= new_calculator
    end

    def solve!(message, facts_and_rules, debug = false)
      puts "********** #{message} #{Time.new}" if debug
      puts JSON.pretty_generate(facts_and_rules)  if debug
      start_time = Time.new
      begin
        solution = calculator.solve!(facts_and_rules)
      rescue => e
        puts JSON.pretty_generate(facts_and_rules)
        puts e.message
        raise e
      end
      end_time = Time.new
      solution[:elapsed_time] = (end_time - start_time)
      puts " #{Time.new} => #{solution[:amount]}"  if debug
      puts JSON.pretty_generate(solution) if debug
      solution
    end

    def validate_expression(formula)
      expression = formula.expression.gsub( /%{(.*)}/ ) {|c| "1, 2" }
      @@calculator.dependencies(expression)
    rescue  Dentaku::TokenizerError => e
      formula.errors[:expression] << e.message
    rescue Dentaku::ParseError => e
      formula.errors[:expression] << e.message
    end

    private

    def calculator
      @@calculator
    end

    def new_calculator
      score_table = lambda do |*args|
        target = args.shift
        args.each_slice(3).find do |lower, greater, result|
          greater.nil? || result.nil? ? true : lower <= target && target < greater
        end.last
      end

      avg_function = lambda do |*args|
        args.inject(0.0) { |sum, el| sum + el } / args.size
      end
      sum_function = lambda do |*args|
        args.inject(0.0) { |sum, x| sum + x }
      end

      between = ->(lower, score, greater) { lower <= score && score <= greater }

      calculator = Dentaku::Calculator.new
      calculator.add_function(:between, :logical, between)
      calculator.add_function(:abs, :number, ->(number) { number.abs })
      calculator.add_function(:score_table, :numeric, score_table)
      calculator.add_function(:avg, :numeric, avg_function)
      calculator.add_function(:sum, :numeric, sum_function)
      calculator
   end

 end
end
