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
  def tarif(_entity, _date, activity)
    tarifs = [4.0, 115.0, 82.0, 206.0]
    tarifs[activity.id - 1]
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

def new_calculator
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
  calculator
end

entity = Struct::Entity.new(1, "Phu Bahoma", %w(phu clinic))

class ::BigDecimal
  def encode_json(opts = nil)
    "%.10f" % self
  end
end
class ::Float
  def encode_json(opts = nil)
    "%.10f" % self
  end
end


def solve!(message, calculator, facts_and_rules, debug = false)
  puts "********** #{message} #{Time.new}" if debug
  puts JSON.pretty_generate(facts_and_rules)  if debug
  start_time = Time.new
  solution = calculator.solve!(facts_and_rules)
  end_time = Time.new
  solution[:elapsed_time] = (end_time - start_time)
  puts " #{Time.new} => #{solution[:amount]}"  if debug
  puts JSON.pretty_generate(solution) if debug
  solution
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
        "IF(difference_percentage < 5, verified * tarif , 0.0)",
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

  # build from data element group and analytics api
  values_and_activities = [
    [Struct::Activity.new(1, "Number of new outpatient consultations for curative care consultations"),
     Struct::Values.new(nil, 655.0, 655.0, 0.0)],
    [Struct::Activity.new(2, "Number of pregnant women having their first antenatal care visit in the first trimester"),
     Struct::Values.new(nil, 0.0, 0.0, 0.0)],
    [Struct::Activity.new(3, "Number of pregnant women with fourth or last antenatal care visit in last month of pregnancy"),
     Struct::Values.new(nil, 2.0, 0.0, 0.0)],
    [Struct::Activity.new(4, "Number of new outpatient consultations for curative care consultations"),
     Struct::Values.new(nil, 7.0, 7.0, 0.0)]

  ]

  invoice_details = [:declared, :verified, :difference_percentage, :quantity, :tarif, :amount, :actictity_name]
  total_amount = 0.0
  values_and_activities.each do |activity, values|
    calculator = new_calculator
    # from code
    activity_tarification_facts = {
      tarif: tarification_service.tarif(entity, date, activity)
    }
    facts_and_rules = {}
                      .merge(activity_rule.to_facts)
                      .merge(actictity_name: "'#{activity.name}'")
                      .merge(activity_tarification_facts)
                      .merge(values.to_facts)

    solution = solve!(activity.name.to_s, calculator, facts_and_rules)

    details_values = invoice_details.map { |k| d_to_s(solution[k])}

    puts details_values.join("\t")
    total_amount += solution[:amount]
  end
  puts "TOTAL #{total_amount}"
end

def d_to_s(decimal)
  return "%.0f" % decimal if decimal.is_a? Numeric
  return decimal
end

entity = Struct::Entity.new(1, "Maqokho HC", ["Hospital"])

generate_invoice(entity, Date.new)
