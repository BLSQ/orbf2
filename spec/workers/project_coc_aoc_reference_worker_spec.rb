require "rails_helper"
require_relative "./dhis2_snapshot_fixture"

RSpec.describe ProjectCocAocReferenceWorker do
  include Dhis2SnapshotFixture
  include_context "basic_context"

  let(:program) { create :program }

  let!(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program
    project
  end

  let(:worker) { described_class.new }

  let(:default_category_combo_id) { "bRowv6yZOF2" }

  it "assigns combos" do
    stub_category_option_combos
    stub_default_category_combos

    worker.perform(project.id)

    project.reload
    expect(project.default_coc_reference).to eq(default_category_combo_id)
    expect(project.default_aoc_reference).to eq(default_category_combo_id)
  end

  def stub_category_option_combos
    stub_request(:get, "http://play.dhis2.org/demo/api/categoryOptionCombos?fields=id,name,categoryCombo&filter=name:eq:default")
      .to_return(body: JSON.pretty_generate(
        "pager":                {
          "page":      1,
          "pageCount": 1,
          "total":     1,
          "pageSize":  50
        },
        "categoryOptionCombos": [
          {
            "name":          "default",
            "id":            default_category_combo_id,
            "categoryCombo": {
              "id": "p0KPaWEg3cf"
            }
          }
        ]
      ))
  end

  def stub_default_category_combos
    stub_request(:get, "http://play.dhis2.org/demo/api/categoryCombos?fields=id,name,isDefault&filter=name:eq:default")
      .to_return(body: fixture_content(:dhis2, "default_category.json"))
  end
end
