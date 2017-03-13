require "dentaku"
require "dentaku/calculator"

module Rules
  class Solver
    def initialize
      @@calculator ||= new_calculator
    end

    def solve!(message, facts_and_rules, debug = false)
      puts "********** #{message} #{Time.new}" if debug
      puts JSON.pretty_generate(facts_and_rules) if debug
      start_time = Time.new.utc
      begin
        solution = calculator.solve!(facts_and_rules)
      rescue => e
        puts JSON.pretty_generate(facts_and_rules)
        puts e.message
        # TODO: log stacktrace
        raise SolvingError.new(e.message, facts_and_rules), "Failed to solve this problem #{message} : #{e.message}"
      end
      end_time = Time.new.utc
      solution[:elapsed_time] = (end_time - start_time)
      puts " #{Time.new} => #{solution[:elapsed_time]}" if debug
      puts JSON.pretty_generate([solution]) if debug
      solution.with_indifferent_access
    end

    def validate_expression(formula)
      @@calculator.dependencies(mock_values(formula.expression, formula.rule.available_variables_for_values))
    rescue Dentaku::TokenizerError => e
      formula.errors[:expression] << e.message
    rescue Dentaku::ParseError => e
      formula.errors[:expression] << e.message
    rescue KeyError => e
      formula.errors[:expression] << "#{e.message}. Remove extra spaces or verify it's in the available variables"
    rescue => e
      formula.errors[:expression] << e.message
    end

    def validate_formulas(rule)
      facts = {}.merge(rule.fake_facts)
      rule.formulas.each { |formula| facts[formula.code] = mock_values(formula.expression, rule.available_variables_for_values) }
      facts[:actictity_rule_name] = Solver.escapeString(rule.name)

      solve!("validate_all_formulas", facts)
    rescue Rules::SolvingError => e
      rule.errors[:formulas] << e.original_message
    rescue KeyError => e
      rule.errors[:formulas] << "#{e.message}. Remove extra spaces or verify it's in the available variables"
    rescue => e
      rule.errors[:formulas] << e.message
    end

    def self.escapeString(string)
      "'#{string.tr("'", ' ')}'"
    end

    private

    def mock_values(expression, available_variables_for_values)
      variables = {}
      available_variables_for_values.select {|name|name.ends_with?("_values")}.each do |variable_name|
        raise "please don't add extra spaces in '%{#{variable_name}}'" if variable_name.include?(" ")
        variables[variable_name.to_sym] = "1 , 2"
      end
      expression % variables
    rescue ArgumentError => e
      raise e.message
    end

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
