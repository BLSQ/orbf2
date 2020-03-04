# == Schema Information
#
# Table name: formula_mappings
#
#  id                 :bigint(8)        not null, primary key
#  external_reference :string           not null
#  kind               :string           not null
#  activity_id        :integer
#  formula_id         :integer          not null
#
# Indexes
#
#  index_formula_mappings_on_activity_id  (activity_id)
#  index_formula_mappings_on_formula_id   (formula_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (formula_id => formulas.id)
#

require "rails_helper"

RSpec.describe FormulaMapping, type: :model do
  include_context "basic_context"

  let(:project) { full_project }

  describe "activity rule" do
    let(:package) { project.packages.first }
    let(:activity) { package.activities.first }
    let(:formula) { package.activity_rule.formulas.first }

    it "name formula with activity" do
      project.qualifier = "Pbf"
      activity.code = "HF01"
      formula_mapping = formula.formula_mappings.create!(
        activity:           activity,
        external_reference: "samplede",
        kind:               "activity"
      )
      expect(formula_mapping.names).to eq(
        Dhis2Name.new(
          code:  "HF01 - difference_percentage",
          long:  "Pbf - Difference percentage - HF01 Vaccination",
          short: "Vaccination (Difference percentageHF01)"
        )
      )
    end
  end

  describe "package rule" do
    let(:package) { project.packages.first }
    let(:formula) { package.package_rule.formulas.first }
    it "name formula" do
      project.qualifier = "Pbf"
      formula_mapping = formula.formula_mappings.create!(
        external_reference: "samplede",
        kind:               "package"
      )
      expect(formula_mapping.names).to eq(
        Dhis2Name.new(
          code:  "quantity_total_pma",
          long:  "Pbf - Quantity total pma",
          short: "Quantity total pma"
        )
      )
    end
  end

  describe "payment rule" do
    let(:formula) { project.payment_rules.first.rule.formulas.first }

    it "name formula" do
      project.qualifier = "Pbf"
      formula_mapping = formula.formula_mappings.create!(
        external_reference: "samplede",
        kind:               "payment"
      )
      expect(formula_mapping.names).to eq(
        Dhis2Name.new(
          code:  "quality_bonus_percentage_value",
          long:  "Pbf - Quality bonus percentage value",
          short: "Quality bonus percentage value"
        )
      )
    end
  end
end
