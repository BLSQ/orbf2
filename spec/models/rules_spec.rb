require "rails_helper"

RSpec.describe Rule, kind: :model do
  it "enables paper trail" do
    is_expected.to be_versioned
  end
  let(:project) do
    project = build(:project, engine_version: 2)
    %w[Claimed Verified Tarif].each do |state_name|
      project.states.build(name: state_name)
    end
    project
  end

  let(:quantity_package) do
    p = project.packages.build
    p.states << p.project.states.select { |state| %w[Claimed Verified Tarif].include?(state.name) }.to_a
    p
  end
  let(:quality_package) do
    p = project.packages.build
    p.states << p.project.states.select { |state| ["Claimed", "Verified", "Max. Score"].include?(state.name) }.to_a
    p
  end
  let(:valid_activity_quantity_rule) do
    rule = quantity_package.rules.build(
      name: "Quantité PMA",
      kind: "activity"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :difference_percentage,
      expression:  "if (verified != 0.0, (ABS(claimed - verified) / verified ) * 100.0, 0.0)",
      description: "Pourcentage difference entre déclaré & vérifié"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :quantity,
      expression:  "IF(difference_percentage < 5, verified , 0.0)",
      description: "Quantity for PBF payment"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :amount,
      expression:  "quantity * tarif",
      description: "Total payment"
    )
    rule
  end

  let(:valid_package_quantity_rule) do
    rule = quantity_package.rules.build(
      name: "Quantité PMA",
      kind: "activity"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :difference_percentage,
      expression:  "if (verified != 0.0, (ABS(claimed - verified) / verified ) * 100.0, 0.0)",
      description: "Pourcentage difference entre déclaré & vérifié"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :quantity,
      expression:  "IF(difference_percentage < 5, verified , 0.0)",
      description: "Quantity for PBF payment"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :amount,
      expression:  "quantity * tarif",
      description: "Total payment"
    )

    rule
  end

  let(:valid_package_quality_rule) do
    rule = quality_package.rules.build(
      name: "QUALITY score",
      kind: "package"
    )

    rule.formulas.build(
      rule:        rule,
      code:        :attributed_points,
      expression:  "SUM(%{attributed_points_values})",
      description: "Quality score"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :max_points,
      expression:  "SUM(%{max_points_values})",
      description: "Quality score"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :quality_technical_score_value,
      expression:  "SUM(%{attributed_points_values})/SUM(%{max_points_values}) * 100.0",
      description: "Quality score"
    )

    rule_activity = quality_package.rules.build(
      name: "Qualité assessment",
      kind: "activity"
    )
    rule_activity.formulas.build(
      rule:        rule_activity,
      code:        :attributed_points,
      expression:  "declared",
      description: "Attrib. Points"
    )
    rule_activity.formulas.build(
      rule:        rule_activity,
      code:        :max_points,
      expression:  "tarif",
      description: "Max Points"
    )
    rule_activity.formulas.build(
      rule:        rule_activity,
      code:        :quality_technical_score_value,
      expression:  "if (max_points != 0.0, (attributed_points / max_points) * 100.0, 0.0)",
      description: "Quality score"
    )

    rule
  end

  describe "#available_variables" do
    EXPECTED_VARIABLES = %w[
      %{amount_current_quarter_values}
      %{claimed_current_cycle_values}
      %{claimed_previous_year_same_quarter_values}
      %{claimed_previous_year_values}
      %{difference_percentage_current_quarter_values}
      %{quantity_current_quarter_values}
      %{tarif_current_cycle_values}
      %{tarif_previous_year_same_quarter_values}
      %{tarif_previous_year_values}
      %{verified_current_cycle_values}
      %{verified_previous_year_same_quarter_values}
      %{verified_previous_year_values}
      amount
      claimed
      claimed_is_null
      claimed_level_1
      claimed_level_2
      claimed_level_3
      claimed_level_4
      claimed_level_5
      difference_percentage
      month_of_year
      quantity
      quarter_of_year
      tarif
      tarif_is_null
      tarif_level_1
      tarif_level_2
      tarif_level_3
      tarif_level_4
      tarif_level_5
      verified
      verified_is_null
      verified_level_1
      verified_level_2
      verified_level_3
      verified_level_4
      verified_level_5
    ].freeze

    it "should return all states and scoped states " do
      availailable_variables = valid_package_quantity_rule.available_variables
      expect(availailable_variables).to eq(EXPECTED_VARIABLES), availailable_variables.join("\n")
    end
  end
  describe "validation of formulas" do
    it "should say it's valid for quantity" do
      valid_activity_quantity_rule.valid?
      expect(valid_activity_quantity_rule.errors.full_messages).to eq []
    end

    it "should say it's valid for package quantity" do
      valid_package_quantity_rule.valid?
      expect(valid_package_quantity_rule.errors.full_messages).to eq []
    end

    it "should say it's valid for package quality" do
      valid_package_quality_rule.valid?
      expect(valid_package_quality_rule.errors.full_messages).to eq []
    end

    let(:valid_activity_rule) do
      rule = Rule.new(
        name:     "Quantité PMA",
        kind:     "activity",
        formulas: [
          Formula.new(
            code:        :difference_percentage_bad_ref,
            expression:  "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
            description: "Pourcentage difference entre déclaré & vérifié"
          ),
          Formula.new(
            code:        :quantity,
            expression:  "IF(difference_percentage < 5, verified , 0.0)",
            description: "Quantity for PBF payment"
          ),
          Formula.new(
            code:        :amount,
            expression:  "quantity * tarif",
            description: "Total payment"
          )
        ]
      )
      rule.valid?
      expect(rule.errors.full_messages.first).to include("no value provided for variables: difference_percentage")
    end
  end

  describe "Package involving a decision table" do
    let!(:activity_rule) do
      rule = quality_package.rules.build(
        name: "Quality PMA Budgets",
        kind: "activity"
      )

      rule.formulas.build(
        rule:        rule,
        code:        :max_points,
        expression:  "76.43",
        description: "Max Score"
      )
      rule
    end

    let!(:package_rule_decision_table) do
      rule = quality_package.rules.build(
        name: "Quality PMA Budgets",
        kind: "package"
      )

      rule.formulas.build(
        rule:        rule,
        code:        :quality_assessment_score_for_hf,
        expression:  "SUM(%{max_points_values})",
        description: "Quality Score"
      )
      rule.formulas.build(
        rule:        rule,
        code:        :quality_improvement_incentive_for_hf,
        expression:  "SCORE_TABLE(quality_assessment_score_for_hf,0, 65, 0,65,75, budget_range_1,75,85, budget_range_2)",
        description: "Quality improvement incentive"
      )
      rule.decision_tables.build(
        content: ["in:groupset_code_ppa,in:groupset_code_type,out:budget_range_1,out:budget_range_2",
                  "worldbank,fosa,1000,2000",
                  "worldbank,hospital,3000,4000",
                  "usaid,hospital,3000,4000"].join("\n")
      )
      rule
    end

    it "has validation on the activity rule when the package involves a decision table" do
      activity_rule.valid?
      expect(activity_rule.errors.full_messages).to eq []
    end
    it "has validations for package rule involving a decision table" do
      package_rule_decision_table.valid?
      expect(package_rule_decision_table.errors.full_messages).to eq []
    end
  end

  describe "zone packages" do
    let(:project) do
      project = build(:project, engine_version: 2)
      %w[Claimed].each do |state_name|
        project.states.build(name: state_name)
      end
      project
    end

    let(:quantity_package) do
      p = project.packages.build(kind: "zone")
      p.states << p.project.states.select { |state| %w[Claimed].include?(state.name) }.to_a
      p
    end

    let(:quality_package) do
      p = project.packages.build(kind: "single")
      p.states << p.project.states.select { |state| %w[Claimed].include?(state.name) }.to_a
      p
    end

    let!(:activity_rule) do
      rule = quantity_package.rules.build(
        name: "QUALITY score",
        kind: "activity"
      )

      rule.formulas.build(
        rule:        rule,
        code:        :attributed_points,
        expression:  "claimed / 5 ",
        description: "Quality score"
      )
      rule
    end

    let!(:package_rule) do
      rule = quantity_package.rules.build(
        name: "QUALITY score",
        kind: "package"
      )

      rule.formulas.build(
        rule:        rule,
        code:        :fosa_attributed_points,
        expression:  "SUM(%{attributed_points_values})",
        description: "Quality score"
      )
      rule
    end

    let!(:zone_rule) do
      rule = quantity_package.rules.build(
        name: "QUALITY score",
        kind: "zone"
      )

      rule.formulas.build(
        rule:        rule,
        code:        :zone_attributed_points,
        expression:  "SUM(%{fosa_attributed_points_values}) / zone_constant",
        description: "Quality score"
      )
      rule.formulas.build(
        rule:        rule,
        code:        :zone_constant,
        expression:  "10",
        description: "constant"
      )

      rule
    end

    it "has validations for activity_rules" do
      activity_rule.valid?
      expect(activity_rule.errors.full_messages).to eq []
    end

    it "has validations for package_rules" do
      package_rule.valid?
      expect(package_rule.errors.full_messages).to eq []
    end

    it "has validations for zone_rules" do
      zone_rule.valid?
      expect(zone_rule.errors.full_messages).to eq []
    end

    it "has available_variables for activity_rules" do
      expected = %w[
        %{attributed_points_current_quarter_values}
        %{claimed_current_cycle_values}
        %{claimed_previous_year_same_quarter_values}
        %{claimed_previous_year_values}
        attributed_points
        claimed
        claimed_is_null
        claimed_level_1
        claimed_level_2
        claimed_level_3
        claimed_level_4
        claimed_level_5
        claimed_zone_main_orgunit
        fosa_attributed_points
        month_of_year
        quarter_of_year
      ]
      expect(activity_rule.available_variables).to eq(expected), [
        " got : \n" +
        activity_rule.available_variables.join("\n"),
        "\n expected \n ",
        expected.join("\n"),
        "\ndiff 1\n",
        (activity_rule.available_variables - expected).join("\n"),
        "\n diff 2",
        (expected - activity_rule.available_variables).join("\n")
      ].join
    end

    it "has available_variables for package_rule" do
      expect(package_rule.available_variables).to eq [
        "%{attributed_points_values}",
        "zone_attributed_points", "zone_constant"
      ]
    end

    it "has available_variables for zone_rule" do
      expect(zone_rule.available_variables).to eq [
        "%{fosa_attributed_points_values}",
        "zone_attributed_points",
        "zone_constant"
      ]
    end

    it "detects cycles" do
      package_rule.formulas.first.expression = "SUM(%{attributed_points_values}) / zone_attributed_points"
      package_rule.valid?
      expect(package_rule.errors.full_messages).to eq [
        "Formulas a cycle has been created : topological sort failed:"\
        " [\"zone_attributed_points\", \"fosa_attributed_points\"]"
      ]
    end
  end
end
