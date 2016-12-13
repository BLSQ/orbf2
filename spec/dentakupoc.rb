require "rails_helper"
require "dentaku"
require "dentaku/calculator"

puts "************************************ activity value to amount"

Struct.new("Values", :declared, :verified, :validated) do
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
Struct.new("Package", :id, :name, :entity_groups, :rules, :invoice_details) do
  def apply_for(entity)
    entity_groups.any? { |group| entity.groups.include?(group) }
  end

  def new_values(declared = 0.0, verified = 0.0, validated = 0.0)
    Struct::Values.new(declared, verified, validated)
  end

  def for_quarter(value)
    quarter = []
    quarter << value
    quarter << value
    quarter << value
    quarter
  end

  def package_rule
    rules.find { |r| r.type == :package }
  end

  def activity_rule
    rules.find { |r| r.type == :activity }
  end

  def activity_and_values(_date)
    # build from data element group and analytics api
    activity_and_values_quantity_pma = [ # PMA
      [Struct::Activity.new(1, "Number of new outpatient consultations for curative care consultations"),
       [new_values(655.0, 655.0), new_values(652.0, 652.0), new_values(654.0, 654.0)]],
      [Struct::Activity.new(2, "Number of pregnant women having their first antenatal care visit in the first trimester"),
       [new_values(0.0, 0.0), new_values(1.0, 1.0), new_values(0.0, 1.0)]],
      [Struct::Activity.new(3, "Number of pregnant women with fourth or last antenatal care visit in last month of pregnancy"),
       [new_values(2.0, 0.0), new_values(2.0, 0.0), new_values(2.0, 0.0)]],
      [Struct::Activity.new(4, "Number of new outpatient consultations for curative care consultations"),
       [new_values(7.0, 7.0), new_values(7.0, 7.0), new_values(7.0, 7.0)]],
      [Struct::Activity.new(5, "Number of women delivering in health facilities"),
       [new_values(6.0, 6.0), new_values(6.0, 6.0), new_values(6.0, 6.0)]],
      [Struct::Activity.new(6, "Number of women with newborns with a postnatal care visit between 24 hours and 1 week of delivery"),
       for_quarter(new_values(0.0, 0.0))],
      [Struct::Activity.new(7, "Number of patients referred who arrive at the District/local hospital"),
       for_quarter(new_values(96.0, 96.0))],
      [Struct::Activity.new(8, "Number of new and follow up users of short-term modern contraceptive methods"),
       for_quarter(new_values(0.0, 0.0))],
      [Struct::Activity.new(9, "Number of children under 1 year fully immunized"),
       for_quarter(new_values(13.0, 13.0))],
      [Struct::Activity.new(10, "Number of malnourished children detected and ?treated?"),
       for_quarter(new_values(1.0, 1.0))],
      [Struct::Activity.new(11, "Number of notified HIV-Positive tuberculosis patients completed treatment and/or cured"),
       for_quarter(new_values(0.0, 0.0))],
      [Struct::Activity.new(12, "Number of HIV+ TB patients initiated and currently on ART"),
       for_quarter(new_values(1.0, 1.0))],
      [Struct::Activity.new(13, "Number of children born to HIV-Positive women who receive a confirmatory HIV test at 18 months after birth"),
       for_quarter(new_values(1.0, 1.0))],
      [Struct::Activity.new(14, "Number of children (0-14 years) with HIV infection initiated and currently on ART"),
       for_quarter(new_values(1.0, 1.0))]
    ]

    # PCA
    activity_and_values_quantity_pca = [
      [Struct::Activity.new(51, "Contre référence de l'hopital arrivée au CS"),
       for_quarter(new_values(144, 136, 0.0))],
      [Struct::Activity.new(52, "Femmes enceintes dépistées séropositive et mise sous traitement ARV (tri prophylaxie/trithérapie)"),
       for_quarter(new_values(0, 0, 0.0))],
      [Struct::Activity.new(53, "Clients sous traitement ARV suivi pendant les 6 premiers mois"),
       for_quarter(new_values(5, 5, 0.0))],
      [Struct::Activity.new(54, "Enfants éligibles au traitement ARV et qui ont été initié au traitement ARV au cours du mois"),
       for_quarter(new_values(0, 0, 0.0))],
      [Struct::Activity.new(55, "Accouchement dystocique effectué chez une parturiente référée des Centres de Santé"),
       for_quarter(new_values(46, 46, 0.0))],
      [Struct::Activity.new(56, "Césarienne"),
       for_quarter(new_values(45, 45, 0.0))],
      [Struct::Activity.new(57, "Intervention Chirurgicale en service de Gynécologie Obstétrique et Chirurgie"),
       for_quarter(new_values(47, 47, 0.0))],
      [Struct::Activity.new(58, "Depistage des cas TBC positifs"),
       for_quarter(new_values(2, 2, 0.0))],
      [Struct::Activity.new(59, "Nombre de cas TBC traites et gueris"),
       for_quarter(new_values(3, 3, 0.0))],
      [Struct::Activity.new(60, "IST diagnostiqués et traités"),
       for_quarter(new_values(2, 2, 0.0))],
      [Struct::Activity.new(61, "Diagnostic et traitement des cas de paludisme simple chez les enfants"),
       for_quarter(new_values(18, 18, 0.0))],
      [Struct::Activity.new(62, "Diagnostic et traitement des cas de paludisme grave chez les enfants"),
       for_quarter(new_values(33, 33, 0.0))],
      [Struct::Activity.new(63, "Diagnostic et traitement des cas de paludisme simple chez les femmes enceintes"),
       for_quarter(new_values(0, 0, 0.0))],
      [Struct::Activity.new(64, "Diagnostic et traitement des cas de paludisme grave chez les femmes enceintes"),
       for_quarter(new_values(0, 0, 0.0))]
    ]

    activity_and_values_quality = [
      [Struct::Activity.new(100, "General Management"),
       [new_values(19.0)]],
      [Struct::Activity.new(101, "Environmental Health"),
       [new_values(23.0)]],
      [Struct::Activity.new(102, "General consultations"),
       [new_values(25)]],
      [Struct::Activity.new(103, "Child Survival"),
       [new_values(30)]],
      [Struct::Activity.new(104, "Family Planning"),
       [new_values(9)]],
      [Struct::Activity.new(105, "Maternal Health"),
       [new_values(45)]],
      [Struct::Activity.new(106, "STI, HIV and TB"),
       [new_values(22)]],
      [Struct::Activity.new(107, "Essential drugs Management"),
       [new_values(20)]],
      [Struct::Activity.new(108, "Priority Drugs and supplies"),
       [new_values(20)]],
      [Struct::Activity.new(109, "Community based services"),
       [new_values(12)]]

    ]

    return activity_and_values_quantity_pca if name.downcase.include?("quantité pca")
    return activity_and_values_quantity_pma if name.downcase.include?("quantité pma")
    return activity_and_values_quality if name.downcase.include?("qualité")
    raise "no data for #{name}"
  end

  def to_h
    super.to_h.except(:rules).merge!("rules" => rules.map(&:to_h))
  end
end

Struct.new("TarificationService", :none) do
  def tarif(entity, date, activity)
    tarif = nil
    if activity.id < 50
      # quantité PMA
      tarifs = [4.0, 115.0, 82.0, 206.0, 123, 41.0, 12.0, 240.0, 103.0, 200.0, 370.0, 40.0, 103.0, 60.0]
      tarif = tarifs[activity.id - 1]
    elsif activity.id < 100
      # quantité PCA
      tarifs = [15_000, 17_500, 12_250, 19_250, 35_000, 0, 65_000, 22_750, 26_250, 5000, 330, 5572, 655, 50_075]
      tarif = tarifs[activity.id - 51]
    elsif activity.id < 200
      # qualité
      tarifs = [24, 23, 25, 42, 17, 54, 28, 20, 23, 15]
      tarif = tarifs[activity.id - 100]
    end
    raise "no tarif for #{entity}, #{date} #{activity.name} #{activity.id}" unless tarif
    tarif
  end
end

Struct.new("Formula", :code, :expression, :label) do
end

Struct.new("Rule", :name, :type, :formulas) do
  def to_facts
    facts = {}
    formulas.each { |formula| facts[formula.code] = formula.expression }
    facts[:actictity_rule_name] = "'#{name.tr("'", ' ')}'"
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
  def to_h
    super.to_h.except(:payment_rule, :packages).merge!("packages" => packages.map(&:to_h), "payment_rule" => payment_rule.to_h)
  end
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

def find_project
  package_quantity_pma = Struct::Package.new(
    1,
    "Quantité PMA",
    ["fosa_group_id"],
    [
      Struct::Rule.new(
        "Quantité PMA",
        :activity,
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
      ),
      Struct::Rule.new(
        "Quantité PMA",
        :package,
        [
          Struct::Formula.new(
            :quantity_total,
            "SUM(%{amount_values})",
            "Amount PBF"
          )
        ]
      )
    ],
    [:declared, :verified,
     :difference_percentage, :quantity,
     :tarif, :amount,
     :actictity_name, :quantity_total]
  )

  package_quantity_pca = Struct::Package.new(
    1,
    "Quantité PCA",
    ["hospital_group_id"],
    [
      Struct::Rule.new(
        "Quantité PCA",
        :activity,
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
      ),
      Struct::Rule.new(
        "Quantité PHU",
        :package,
        [
          Struct::Formula.new(
            :quantity_total,
            "SUM(%{amount_values})",
            "Amount PBF"
          )
        ]
      )
    ],
    [:declared, :verified, :difference_percentage, :quantity, :tarif, :amount, :actictity_name, :quantity_total]

  )

  package_quality = Struct::Package.new(
    2,
    "Qualité",
    %w(hospital_group_id fosa_group_id),
    [
      Struct::Rule.new(
        "Qualité assessment",
        :activity,
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
            "if (max_points != 0.0, (attributed_points / max_points) * 100.0, 0.0)",
            "Quality score"
          )
        ]
      ),
      Struct::Rule.new(
        "QUALITY score",
        :package,
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
    ],
    [:attributed_points, :max_points, :quality_technical_score_value, :actictity_name]

  )

  packages = [package_quantity_pma, package_quantity_pca, package_quality]

  project = Struct::Project.new(
    "LESOTHO",
    packages,
    Struct::Rule.new(
      "Payment rule",
      :payment,
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

  project
end

def calculate_activity_results(project, entity, date, tarification_service, calculator)
  selected_packages = project.packages.select { |package| package.apply_for(entity) }
  raise "No package for #{entity.name} #{entity.groups} vs supported groups #{project.packages.flat_map(&:entity_groups).uniq}" if selected_packages.empty?
  selected_packages.map do |package|
    package.activity_and_values(date).map do |activity, values|
      activity_tarification_facts = {
        tarif: tarification_service.tarif(entity, date, activity)
      }

      facts_and_rules = {}
                        .merge(package.activity_rule.to_facts)
                        .merge(actictity_name: "'#{activity.name.tr("'", ' ')}'")
                        .merge(activity_tarification_facts)
                        .merge(values.first.to_facts)

      solution = solve!(activity.name.to_s, calculator, facts_and_rules)

      Struct::ActivityResult.new(package, activity, solution)
    end
  end
end

def calculate_package_results(activity_results, calculator)
  activity_results.flatten.group_by(&:package).map do |package, results|
    variables = {
    }
    results.first.solution.keys.each do |k|
      variables["#{k}_values".to_sym] = solution_to_array(results, k).join(" , ")
    end

    facts_and_rules = {}
    package.package_rule.formulas.each do |formula|
      facts_and_rules[formula.code] = string_template(formula, variables)
    end
    solution_package = solve!("sum activities for #{package.name}", calculator, facts_and_rules)

    Struct::PackageResult.new(package, solution_package)
  end
end

def solution_to_array(results, k)
  results.map do |r|
    begin
      BigDecimal.new(r.solution[k])
      "%.10f" % r.solution[k]
    rescue
      nil
    end
  end
end

def string_template(formula, variables)
  return formula.expression % variables
rescue KeyError => e
  puts "problem with expression #{e.message} : #{formula.code} : #{formula.expression} #{JSON.pretty_generate(variables)}"
  raise e
end

def calculate_payments(project, package_results, calculator)
  package_facts_and_rules = {}
  package_results.each do |package_result|
    package_facts_and_rules = package_facts_and_rules.merge(package_result.solution)
  end
  package_facts_and_rules = package_facts_and_rules.merge(project.payment_rule.to_facts)
  project_solution = solve!("payment rule", calculator, package_facts_and_rules, false)
  project_solution
end

def generate_invoice(entity, date)
  tarification_service = Struct::TarificationService.new(:unused)

  project = find_project
  calculator = new_calculator

  begin
  activity_results = calculate_activity_results(project, entity, date, tarification_service, calculator)
  raise "should have at least one activity_results" if activity_results.empty?
  package_results = calculate_package_results(activity_results, calculator)
  raise "should have at least one package_results" if package_results.empty?
  payments = calculate_payments(project, package_results, calculator)
  dump_invoice(entity, project, activity_results, package_results, payments)
rescue => e
  dump_invoice(entity, project, activity_results, package_results, payments)
  raise e
end
end

def dump_invoice(entity, project, activity_results, package_results, payments)
  puts "-------********* #{entity.name} ************------------"
  if activity_results
    activity_results.flatten.group_by(&:package).map do |package, results|
      puts "************ Package #{package.name} "
      puts package.invoice_details.join("\t")
      results.each do |result|
        line = package.invoice_details.map { |item| d_to_s(result.solution[item]) }
        # line << result.solution.to_json
        puts line.join("\t\t")
      end
      next unless package_results
      package_line = package.invoice_details.map do |item|
        package_result = package_results.find { |pr| pr.package == package }
        d_to_s(package_result.solution[item])
      end
      puts "Totals :  #{package_line.join("\t")}"
    end
  end

  if payments
    package_line = project.payment_rule.formulas.map do |formula|
      [formula.code, d_to_s(payments[formula.code])].join(" : ")
    end
    puts "************ payments "
    puts package_line.join("\n")
  end
  puts
end

def d_to_s(decimal)
  return "%.2f" % decimal if decimal.is_a? Numeric
  decimal
end

puts JSON.pretty_generate(find_project.to_h)

entity = Struct::Entity.new(1, "Maqokho HC", ["hospital_group_id"])

generate_invoice(entity, Date.new)

entity = Struct::Entity.new(1, "fosa", ["fosa_group_id"])

generate_invoice(entity, Date.new)
