require 'test_helper'
require 'dentaku/calculator'

score_table = lambda do |*args|
  target = args.shift
  args.each_slice(3).find do |lower, greater, result|
    greater.nil? || result.nil? ? true : lower <= target && target < greater
  end.last
end

between = ->(lower, score, greater) { lower <= score && score <= greater }

calculator = Dentaku::Calculator.new
calculator.add_function(:between, :logical, between)
calculator.add_function(:abs, :number, ->(number) { number.abs })
calculator.add_function(:score_table, :numeric, score_table)

puts '************************************ activity value to amount'

Struct.new('Values', :activity, :declared, :verified, :validated) do
  def to_facts
    {
      declared: declared,
      verified: verified,
      validated: validated
    }
  end
end

Struct.new('Entity', :id, :name, :groups) do
end
Struct.new('Activity', :id, :name) do
end

Struct.new('TarificationService', :none) do
  def tarif(_entity, _date, _activity)
    43.3
  end
end

tarification_service = Struct::TarificationService.new(:unused)
entity = Struct::Entity.new(1, 'Chc Suarlée', ['group1'])
activity = Struct::Entity.new(1, 'Consultation pédiatrique')
values = Struct::Values.new(activity, 1.5, 2.5, 2.0)
zero_values = Struct::Values.new(activity, 0.0, 0.0, 0.0)
# pure json based on PBF manager
activity_rule = {
  difference: 'declared - verified',
  percentage_difference: 'if (verified != 0.0, (ABS(difference) / verified ) * 100.0, 0.0)',
  is_difference_lower_enough: 'percentage_difference < 50.0',
  amount: 'IF(is_difference_lower_enough, validated * tarif , 0.0)'
}

# from code
tarification_facts = {
  tarif: tarification_service.tarif(entity, Date.new, activity)
}

def solve!(message, calculator, facts_and_rules)
  puts "********** #{message} #{Time.new}"
  puts JSON.pretty_generate(facts_and_rules)
  start_time = Time.new
  solution = calculator.solve!(facts_and_rules)
  end_time = Time.new
  solution[:elapsed_time] = (end_time - start_time)
  puts " #{Time.new} => #{solution[:amount]}"
  puts JSON.pretty_generate(solution)
end

solve!('normal', calculator,
       activity_rule
       .merge(values.to_facts)
       .merge(tarification_facts))

solve!('zero', calculator,
       activity_rule
       .merge(zero_values.to_facts)
       .merge(tarification_facts))

puts ''
puts '************************************ SCORE table example'
need_to_compute = {}.merge(

  score: 90,
  scoring: "score_table(score,
  10,30, 13.0, /* if between 10 and 30 then scoring will 13.0 %
  30,40, 26.0,
         42.0)",
  #  percentage: "IF (between(1,score,30 ), 10, IF (between(31,score,40 ), 20, 50))",
  amount: '613.1 * (scoring /100.0 )'
)

puts JSON.pretty_generate(need_to_compute)
puts calculator.dependencies('amount')
puts JSON.pretty_generate(calculator.solve!(need_to_compute))
# {"score":10,"percentage":10,"amount":"60.0"}
