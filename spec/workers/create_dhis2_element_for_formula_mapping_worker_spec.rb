require "rails_helper"

require_relative 'dhis2_stubs'

RSpec.describe CreateDhis2ElementForFormulaMappingWorker do
  include Dhis2Stubs
  include_context "basic_context"

  let(:worker) { described_class.new }

  it "create a data element and associated activity state" do
    package = full_project.packages.first
    activity = package.activities.first
    formula = package.activity_rule.formulas.first

    stub_default_category_success
    stub_create_dataelement
    stub_find_data_element

    worker.perform(
      full_project.id,
      "activity_id"  => activity.id,
      "formula_id"   => formula.id,
      "kind"         => "activity",
      "data_element" => {
        "name"       => "long and descriptrive name",
        "short_name" => "short name",
        "code"       => "code"
      }
    )

    formula_mapping = FormulaMapping.last
    expect(formula_mapping.external_reference).to eq("azeaze")
  end
end
