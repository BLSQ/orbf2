require "rails_helper"

RSpec.describe Rule, kind: :model do
  let(:quantity_package) { build(:package) }
  let(:quality_package) { build(:package) }
  let(:valid_activity_quantity_rule) do
    rule = quantity_package.rules.build(
      name: "Quantité PMA",
      kind: "activity"
    )
    rule.formulas.build(
      rule:        rule,
      code:        :difference_percentage,
      expression:  "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
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
      expression:  "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
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
    rule
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
end
