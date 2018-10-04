
require "rails_helper"

RSpec.describe Analytics::IndicatorCalculator, type: :services do
  def parse(expression)
    Analytics::IndicatorCalculator.parse_expression(expression)
  end

  describe "#parse_expression" do
    it "parses sum and non specifiedcategory" do
      expect(parse('#{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}')).to eq(
        [
          { expression:     '#{dhjgLt7EYmu.se1qWfbtkmx}',
            data_element:   "dhjgLt7EYmu",
            category_combo: "se1qWfbtkmx" },
          { expression:     '#{xtVtnuWBBLB}',
            data_element:   "xtVtnuWBBLB",
            category_combo: nil }
        ]
      )
    end

    it "reject non supported operands " do
      expect do
        expect(parse('#{dhjgLt7EYmu.se1qWfbtkmx}-#{xtVtnuWBBLB}'))
      end.to raise_error(Analytics::IndicatorCalculator::UnsupportedExpressionException)
    end

    it "reject non supported operands " do
        expect(parse('0')).to eq []
    end

    it "reject non supported grouping " do
      expect do
        parse('(#{dhjgLt7EYmu.se1qWfbtkmx})+#{xtVtnuWBBLB}')
      end.to raise_error(Analytics::IndicatorCalculator::UnsupportedExpressionException)
    end

    it "reject non supported reference to constants " do
      expect do
        parse('C{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}')
      end.to raise_error(Analytics::IndicatorCalculator::UnsupportedExpressionException)
    end
  end

  describe "#calculate" do
    let(:values) do
      JSON.parse(fixture_content(:dhis2, "datasetvalues.json"))["dataValues"].map do |e|
        OpenStruct.new(Dhis2::Case.deep_change(e, :underscore))
      end
    end
    let(:calculator) { Analytics::IndicatorCalculator.new }

    it "return values for indicators" do
      parsed_expressions = { "indicator" => parse('#{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}') }
      indicator_values = calculator.calculate(parsed_expressions, values)
      expect(indicator_values).to eq(
        [
          { dataElement:         "indicator",
            period:              "201501",
            orgUnit:             "CV4IXOSr5ky",
            value:               0.05,
            categoryOptionCombo: nil },
          { dataElement:         "indicator",
            period:              "201502",
            orgUnit:             "CV4IXOSr5ky",
            value:               5.05,
            categoryOptionCombo: nil },
          { dataElement:         "indicator",
            period:              "201602",
            orgUnit:             "CV4IXOSr5ky",
            value:               0.05,
            categoryOptionCombo: nil }
        ].map { |e| OpenStruct.new(Dhis2::Case.deep_change(e, :underscore)) }
      )
    end
  end
end
