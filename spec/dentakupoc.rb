require "rails_helper"
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
Struct.new("Package", :id, :name, :rules, :invoice_details, :to_sum) do
  def activity_and_values(_date)
    # build from data element group and analytics api
    activity_and_values_quantity = [
      [Struct::Activity.new(1, "Number of new outpatient consultations for curative care consultations"),
       Struct::Values.new(nil, 655.0, 655.0, 0.0)],
      [Struct::Activity.new(2, "Number of pregnant women having their first antenatal care visit in the first trimester"),
       Struct::Values.new(nil, 0.0, 0.0, 0.0)],
      [Struct::Activity.new(3, "Number of pregnant women with fourth or last antenatal care visit in last month of pregnancy"),
       Struct::Values.new(nil, 2.0, 0.0, 0.0)],
      [Struct::Activity.new(4, "Number of new outpatient consultations for curative care consultations"),
       Struct::Values.new(nil, 7.0, 7.0, 0.0)],
      [Struct::Activity.new(5, "Number of women delivering in health facilities"),
       Struct::Values.new(nil, 6.0, 6.0, 0.0)],
      [Struct::Activity.new(6, "Number of women with newborns with a postnatal care visit between 24 hours and 1 week of delivery"),
       Struct::Values.new(nil, 0.0, 0.0, 0.0)],
      [Struct::Activity.new(7, "Number of patients referred who arrive at the District/local hospital"),
       Struct::Values.new(nil, 96.0, 96.0, 0.0)],
      [Struct::Activity.new(8, "Number of new and follow up users of short-term modern contraceptive methods"),
       Struct::Values.new(nil, 0.0, 0.0, 0.0)],
      [Struct::Activity.new(9, "Number of children under 1 year fully immunized"),
       Struct::Values.new(nil, 13.0, 13.0, 0.0)],
      [Struct::Activity.new(10, "Number of malnourished children detected and ?treated?"),
       Struct::Values.new(nil, 1.0, 1.0, 0.0)],
      [Struct::Activity.new(11, "Number of notified HIV-Positive tuberculosis patients completed treatment and/or cured"),
       Struct::Values.new(nil, 0.0, 0.0, 0.0)],
      [Struct::Activity.new(12, "Number of HIV+ TB patients initiated and currently on ART"),
       Struct::Values.new(nil, 1.0, 1.0, 0.0)],
      [Struct::Activity.new(13, "Number of children born to HIV-Positive women who receive a confirmatory HIV test at 18 months after birth"),
       Struct::Values.new(nil, 1.0, 1.0, 0.0)],
      [Struct::Activity.new(14, "Number of children (0-14 years) with HIV infection initiated and currently on ART"),
       Struct::Values.new(nil, 1.0, 1.0, 0.0)]
    ]

    activity_and_values_quality = [
      [Struct::Activity.new(100, "General Management"),
       Struct::Values.new(nil, 19.0, 0.0, 0.0)],
      [Struct::Activity.new(101, "Environmental Health"),
       Struct::Values.new(nil, 23.0, 0.0, 0.0)],
      [Struct::Activity.new(102, "General consultations"),
       Struct::Values.new(nil, 25, 0.0, 0.0)],
      [Struct::Activity.new(103, "Child Survival"),
       Struct::Values.new(nil, 30, 0.0, 0.0)],
      [Struct::Activity.new(104, "Family Planning"),
       Struct::Values.new(nil, 9, 0.0, 0.0)],
      [Struct::Activity.new(105, "Maternal Health"),
       Struct::Values.new(nil, 45, 0.0, 0.0)],
      [Struct::Activity.new(106, "STI, HIV and TB"),
       Struct::Values.new(nil, 22, 0.0, 0.0)],
      [Struct::Activity.new(107, "Essential drugs Management"),
       Struct::Values.new(nil, 20, 0.0, 0.0)],
      [Struct::Activity.new(108, "Priority Drugs and supplies"),
       Struct::Values.new(nil, 20, 0.0, 0.0)],
      [Struct::Activity.new(109, "Community based services"),
       Struct::Values.new(nil, 12, 0.0, 0.0)]

    ]

    return activity_and_values_quantity if name.downcase.include?("quantité")
    return activity_and_values_quality if name.downcase.include?("qualité")
  end

  def to_h
    super.to_h.except(:rules,:to_sum).merge!("rules" => rules.map(&:to_h), "to_sum" => to_sum.to_h)
  end
end

Struct.new("TarificationService", :none) do
  def tarif(_entity, _date, activity)
    if activity.id < 100
      # quantité PMA
      tarifs = [4.0, 115.0, 82.0, 206.0, 123, 41.0, 12.0, 240.0, 103.0, 200.0, 370.0, 40.0, 103.0, 60.0]
      return tarifs[activity.id - 1]
    end
    if activity.id < 200
      # qualité
      tarifs = [24, 23, 25, 42, 17, 54, 28, 20, 23, 15]
      return tarifs[activity.id - 100]
    end
  end
end

Struct.new("Formula", :code, :expression, :label) do
end

Struct.new("Rule", :name, :formulas) do
  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = "'#{name}'"
    facts
  end

  def to_h
    super.to_h.except(:formulas).merge!("formulas" => formulas.map(&:to_h))
  end
end

Struct.new("ActivityResult", :package, :activity, :solution) do
end
Struct.new("PackageResult", :package, :solution) do
  def to_s
    "#{package.name} #{solution}"
  end
end


Struct.new("Project", :name, :packages, :payment_rule) do
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

entity = Struct::Entity.new(1, "Phu Bahoma", %w(phu clinic))

class ::BigDecimal
  def encode_json(_opts = nil)
    "%.10f" % self
  end
end
class ::Float
  def encode_json(_opts = nil)
    "%.10f" % self
  end
end

def solve!(message, calculator, facts_and_rules, debug = false)
  puts "********** #{message} #{Time.new}" if debug
  puts JSON.pretty_generate(facts_and_rules)  if debug
  start_time = Time.new
  begin
    solution = calculator.solve!(facts_and_rules)
  rescue => e
    puts facts_and_rules
    puts e.message
    raise e
  end
  end_time = Time.new
  solution[:elapsed_time] = (end_time - start_time)
  puts " #{Time.new} => #{solution[:amount]}"  if debug
  puts JSON.pretty_generate(solution) if debug
  solution
end

def generate_invoice(entity, date)
  tarification_service = Struct::TarificationService.new(:unused)

  package_quantity_pma = Struct::Package.new(
    1,
    "Quantité PMA",
    [
      Struct::Rule.new(
        "Quantité PHU",
        [
          Struct::Formula.new(
            :difference_percentage,
            "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
            "Pourcentage difference entre déclaré & vérifié"
          ),
          Struct::Formula.new(
            :quantity,
            "IF(difference_percentage < 5, verified , 0.0)",
            "Quantity for PBF payment"
          ),
          Struct::Formula.new(
            :amount,
            "quantity * tarif",
            "Total payment"
          )
        ]
      )
    ],
    [:declared, :verified, :difference_percentage, :quantity, :tarif, :amount, :actictity_name],
    Struct::Rule.new(
      "Quantité PHU",
      [
        Struct::Formula.new(
          :quantity_total,
          "SUM(%{amount_values})",
          "Amount PBF"
        )
      ]
    )
  )

  package_quality = Struct::Package.new(
    2,
    "Qualité",
    [
      Struct::Rule.new(
        "Quantité assessment",
        [
          Struct::Formula.new(
            :attributed_points,
            "declared",
            "Attrib. Points"
          ),
          Struct::Formula.new(
            :max_points,
            "tarif",
            "Max Points"
          ),
          Struct::Formula.new(
            :percentage,
            "(attributed_points / max_points) * 100.0",
            "Quality score"
          )
        ]
      )

    ],
    [:attributed_points, :max_points, :quality_technical_score_value, :actictity_name],

    Struct::Rule.new(
      "QUALITY score",
      [
        Struct::Formula.new(
          :attributed_points,
          "SUM(%{attributed_points_values})",
          "Quality score"
        ),
        Struct::Formula.new(
          :max_points,
          "SUM(%{max_points_values})",
          "Quality score"
        ),
        Struct::Formula.new(
          :quality_technical_score_value,
          "SUM(%{attributed_points_values})/SUM(%{max_points_values}) * 100.0",
          "Quality score"
        )
      ]
    )
  )

  packages = [package_quantity_pma, package_quality]

  project = Struct::Project.new(
    "LESOTHO",
    packages,
    Struct::Rule.new(
      "Payment rule",
      [
        Struct::Formula.new(
          :quality_bonus_percentage_value,
          "IF(quality_technical_score_value > 50, (0.35 * quality_technical_score_value) + (0.30 * 10.0), 0.0) /*todo replace with survey score*/",
          "Quality bonus percentage"
        ),
        Struct::Formula.new(
          :quality_bonus_value,
          "quantity_total * quality_bonus_percentage_value",
          "Bonus qualité "
        ),
        Struct::Formula.new(
          :quaterly_payment,
          "quantity_total + quality_bonus_value",
          "Quarterly Payment"
        )
      ]
    )

  )

  puts JSON.pretty_generate([package_quantity_pma.to_h, package_quality.to_h])
  calculator = new_calculator
  solutions = invoice_details_per_package = packages.map do |package|
    package.activity_and_values(date).map do |activity, values|
      # from code
      activity_tarification_facts = {
        tarif: tarification_service.tarif(entity, date, activity)
      }
      facts_and_rules = {}
                        .merge(package.rules.first.to_facts)
                        .merge(actictity_name: "'#{activity.name}'")
                        .merge(activity_tarification_facts)
                        .merge(values.to_facts)

      solution = solve!(activity.name.to_s, calculator, facts_and_rules)

      Struct::ActivityResult.new(package, activity, solution)
    end
  end
  #  puts JSON.pretty_generate(solutions)
  package_results = solutions.flatten.group_by(&:package).map do |package, results|
    results.each do |result|
      line = package.invoice_details.map { |item| d_to_s(result.solution[item]) }
      puts line.join("\t")
    end

    variables = {
    }
    results.first.solution.keys.each do |k|
      variables["#{k}_values".to_sym] = results.map do |r|
        begin
          BigDecimal.new(r.solution[k])
          "%.10f" % r.solution[k]
        rescue
          nil
        end
      end.join(" , ")
    end

    facts_and_rules = {}
    begin
      package.to_sum.formulas.each do |formula|
        facts_and_rules[formula.code] = formula.expression % variables
      end
    rescue KeyError => e
      puts "problem with expression #{e.message}"
      puts "package.to_sum.formulas.first.expression #{package.to_sum.formulas.first.expression} vs #{JSON.pretty_generate(variables)}"
      raise e
    end
    solution_package = solve!("sum activities for #{package.name}", calculator, facts_and_rules, false)
    package_line = package.invoice_details.map { |item| d_to_s(solution_package[item]) }
    puts "Totals :  #{package_line.join("\t")}"

    Struct::PackageResult.new(package, solution_package)
  end


  package_facts_and_rules = {}
  package_results.each do |package_result|
    package_facts_and_rules = package_facts_and_rules.merge(package_result.solution)
  end
  package_facts_and_rules = package_facts_and_rules.merge(project.payment_rule.to_facts)
  puts package_facts_and_rules
  project_solution = solve!("payment rule", calculator, package_facts_and_rules, false)
  package_line = project.payment_rule.formulas.map { |formula| [formula.code, d_to_s(project_solution[formula.code])].join(" : ") }
  puts package_line.join("\n")
end

def d_to_s(decimal)
  return "%.0f" % decimal if decimal.is_a? Numeric
  decimal
end

entity = Struct::Entity.new(1, "Maqokho HC", ["Hospital"])

generate_invoice(entity, Date.new)
