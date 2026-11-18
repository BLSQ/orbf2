# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataElementCreator do
  let(:project) { build :project, dhis2_url: "https://dhis2.example.org" }
  let(:attributes) do
    {
      name:             "Consultation externe - 0 à 1 mois - indigent - taux validation",
      short_name:       "Cons ext 0-1m indigent - taux val",
      code:             "quant98_taux_validation",
      value_type:       "UNIT_INTERVAL",
      aggregation_type: "AVERAGE"
    }
  end

  subject(:creator) { described_class.new(project) }

  def created_payload
    payload = nil
    expect(a_request(:post, "#{project.dhis2_url}/api/metadata?preheatCache=false").with do |request|
      payload = JSON.parse(request.body)
    end).to have_been_made.once
    payload["dataElements"].first
  end

  def expect_refused(message)
    expect { creator.call(attributes) }.to raise_error(DataElementCreator::Error, message)
  end

  context "when dhis2 accepts the data element" do
    before do
      stub_default_category_combo(project)
      stub_metadata_import(project)
      stub_data_element_by_code(project, "quant98_taux_validation", "newDeId0001")
    end

    it "returns the id of the created data element" do
      expect(creator.call(attributes)).to eq("newDeId0001")
    end

    it "creates an aggregate data element with the given names, code and types" do
      creator.call(attributes)

      expect(created_payload).to include(
        "name"            => attributes[:name],
        "shortName"       => attributes[:short_name],
        "code"            => "quant98_taux_validation",
        "valueType"       => "UNIT_INTERVAL",
        "aggregationType" => "AVERAGE",
        "domainType"      => "AGGREGATE",
        "categoryCombo"   => { "id" => "p0KPaWEg3cf", "name" => "default" }
      )
    end

    it "strips the values and accepts string keys" do
      creator.call(attributes.transform_keys(&:to_s).merge("name" => "  #{attributes[:name]} "))

      expect(created_payload["name"]).to eq(attributes[:name])
    end
  end

  describe "validation, before calling dhis2" do
    it "refuses too long names, short names and codes" do
      attributes.merge!(name: "n" * 231, short_name: "s" * 51, code: "c" * 51)

      expect_refused(
        "name is too long (231, max 230), short_name is too long (51, max 50), code is too long (51, max 50)"
      )
    end

    it "accepts the maximum lengths" do
      stub_default_category_combo(project)
      stub_metadata_import(project)
      stub_data_element_by_code(project, "c" * 50, "newDeId0001")
      attributes.merge!(name: "n" * 230, short_name: "s" * 50, code: "c" * 50)

      expect(creator.call(attributes)).to eq("newDeId0001")
    end

    it "requires the name, short name and code" do
      attributes.merge!(name: " ", short_name: nil)
      attributes.delete(:code)

      expect_refused("name is required, short_name is required, code is required")
    end

    it "refuses unsupported value and aggregation types" do
      attributes.merge!(value_type: "TEXT", aggregation_type: "COUNT")

      expect_refused("unsupported value type TEXT, unsupported aggregation type COUNT")
    end
  end

  context "when dhis2 refuses the data element" do
    before { stub_default_category_combo(project) }

    let(:duplicate) { "Property `code` with value `quant98_taux_validation` on object ... already exists" }

    it "gives the dhis2 error reports of an ERROR import report" do
      stub_metadata_import(project, body: refused_import_report(duplicate))

      expect_refused("dhis2 refused the data element: #{duplicate}")
    end

    it "gives the dhis2 error reports of a 409 conflict" do
      stub_metadata_import(project, status: 409, body: { status: "ERROR", response: refused_import_report(duplicate) })

      expect_refused("dhis2 refused the data element: #{duplicate}")
    end

    it "says when the created data element can't be found by its code" do
      stub_metadata_import(project)
      stub_data_element_by_code(project, "quant98_taux_validation", nil)

      expect_refused("data element quant98_taux_validation created but not found by its code")
    end
  end
end
