require "spec_helper"
require "dentaku"
require "dentaku/calculator"

puts "************************************ activity value to amount"

Struct.new("Values", :activity, :declared, :verified, :validated) do
  def to_facts
    {
      declared:  declared,
      verified:  verified,
      validated: validated
    }
  end
end

Struct.new("Entity", :id, :name, :groups) do
end
Struct.new("Activity", :id, :name) do
end
Struct.new("Package", :id, :name, :rules) do
end

Struct.new("TarificationService", :none) do
  def tarif(_entity, _date, _activity)
    43.3
  end
end

Struct.new("Formula", :code, :expression, :label) do
end

Struct.new("Rule", :name, :formulas) do
  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts
  end
end

entity = Struct::Entity.new(1, "Phu Bahoma", %w(phu clinic))

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

def generate_invoice(entity, date)
  tarification_service = Struct::TarificationService.new(:unused)

  activity_rule = Struct::Rule.new(
    "Quantité PHU",
    [
      Struct::Formula.new(
        :difference_percentage,
        "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
        "Pourcentage difference entre déclaré & vérifié"
      ),
      Struct::Formula.new(
        :quantity,
        "IF(difference_percentage < 5.0, validated * tarif , 0.0)",
        "Quantity for PBF payment"
      ),
      Struct::Formula.new(
        :amount,
        "quantity * tarif",
        "Total payment"
      )
    ]
  )
  package = Struct::Package.new(1, "Quantité PMA", [activity_rule])

  activity = Struct::Entity.new(1, "Consultation pédiatrique")
  values = Struct::Values.new(activity, 1.5, 2.5, 2.0)
  zero_values = Struct::Values.new(activity, 0.0, 0.0, 0.0)

  # from code
  activity_tarification_facts = {
    tarif: tarification_service.tarif(entity, date, activity)
  }
  facts_and_rules = {}
                    .merge(activity_rule.to_facts)
                    .merge(activity_tarification_facts)
                    .merge(values.to_facts)
  puts facts_and_rules

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
  solve!("message", calculator, facts_and_rules)
end

generate_invoice(entity, Date.new)
