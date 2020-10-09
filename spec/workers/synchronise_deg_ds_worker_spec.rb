# frozen_string_literal: true

require "rails_helper"

RSpec.describe SynchroniseDegDsWorker do
  include_context "basic_context"

  describe "for legacy synchro" do
    let(:project) { full_project }

    let(:claimed_deg) { "{\"dataElementGroups\":[{\"name\":\"ORBF - Claimeds - Quantity PMA\",\"shortName\":\"ORBF-claimed-Quantity PMA\",\"code\":\"ORBF-claimed-Quantity PMA\",\"dataElements\":[{\"id\":\"cl-ext-2\"},{\"id\":\"clext1\"}]}]}" }
    let(:verified_deg) { "{\"dataElementGroups\":[{\"name\":\"ORBF - Verifieds - Quantity PMA\",\"shortName\":\"ORBF-verified-Quantity PMA\",\"code\":\"ORBF-verified-Quantity PMA\",\"dataElements\":[]}]}" }
    let(:tarif_deg) { "{\"dataElementGroups\":[{\"name\":\"ORBF - Tarifs - Quantity PMA\",\"shortName\":\"ORBF-tarif-Quantity PMA\",\"code\":\"ORBF-tarif-Quantity PMA\",\"dataElements\":[{\"id\":\"tarif-ext-2\"},{\"id\":\"tarif-ext-1\"}]}]}" }

    let(:claimed_dataset) { "{\"dataSets\":[{\"name\":\"ORBF - Claimeds - Quantity PMA\",\"shortName\":\"ORBF-claimed-Quantity PMA\",\"code\":\"ORBF-claimed-Quantity PMA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"},\"openFuturePeriods\":13}]}" }
    let(:verified_dataset) { "{\"dataSets\":[{\"name\":\"ORBF - Verifieds - Quantity PMA\",\"shortName\":\"ORBF-verified-Quantity PMA\",\"code\":\"ORBF-verified-Quantity PMA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"},\"openFuturePeriods\":13}]}" }
    let(:tarif_dataset) { "{\"dataSets\":[{\"name\":\"ORBF - Tarifs - Quantity PMA\",\"shortName\":\"ORBF-tarif-Quantity PMA\",\"code\":\"ORBF-tarif-Quantity PMA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"},\"openFuturePeriods\":13}]}" }
    let(:all_deg) do
      [
        claimed_deg,
        verified_deg,
        tarif_deg
      ]
    end

    let(:all_dataset) do
      [
        claimed_dataset,
        verified_dataset,
        tarif_dataset
      ]
    end

    it "should create" do
      # minimize the project packages to ease stubbing
      project.update(read_through_deg: false)
      project.payment_rules.destroy_all
      project.packages[1..-1].map(&:destroy)
      project.packages.first.activities.first.activity_states.first.update(kind: "indicator", external_reference: "indicator-dhis-id")
      stub_all_indicators
      all_deg.each do |deg|
        stub_data_elements_groups_creation(deg)
        stub_find_data_element_group_by_name(deg)
      end
      stub_category_combos
      all_dataset.each do |ds|
        stub_create_dataset(ds)
        stub_find_dataset_by_name(ds)
        stub_update_data_element_sets
      end
      stub_data_elements_in_dataset("clext1")
      stub_data_elements_in_dataset("cl-ext-2")
      stub_data_elements_in_dataset("tarif-ext-1")
      stub_data_elements_in_dataset("tarif-ext-2")

      SynchroniseDegDsWorker.new.perform(project.project_anchor.id)
    end

    def stub_all_indicators
      stub_request(:get, "#{project.dhis2_url}/api/indicators?fields=:all&pageSize=50000")
        .to_return(status: 200, body: fixture_content(:dhis2, "one_indicator.json"))
    end

    def stub_data_elements_groups_creation(deg)
      stub_request(:post, "http://play.dhis2.org/demo/api/metadata")
        .with(body: deg)
        .to_return(status: 200, body: "", headers: {})
    end

    def stub_update_data_element_sets
      stub_request(:put, "http://play.dhis2.org/demo/api/dataSets/")
        .to_return(status: 200, body: "", headers: {})
    end

    def stub_find_data_element_group_by_name(deg)
      stub_request(:get, "http://play.dhis2.org/demo/api/dataElementGroups?fields=:all&filter=name:eq:#{JSON.parse(deg)['dataElementGroups'].first['name']}")
        .to_return(status: 200, body: deg)
    end

    def stub_category_combos
      stub_request(:get, "http://play.dhis2.org/demo/api/categoryCombos?fields=:all&filter=name:eq:default")
        .to_return(status: 200, body: fixture_content(:dhis2, "category_combos.json"))
    end

    def stub_create_dataset(dataset)
      stub_request(:post, "http://play.dhis2.org/demo/api/metadata")
        .with(body: dataset)
        .to_return(status: 200, body: "", headers: {})
    end

    def stub_find_dataset_by_name(dataset)
      stub_request(:get, "http://play.dhis2.org/demo/api/dataSets?fields=:all&filter=name:eq:#{JSON.parse(dataset)['dataSets'].first['name']}")
        .to_return(status: 200, body: dataset)
    end

    def stub_data_elements_in_dataset(id)
      stub_request(:post, "http://play.dhis2.org/demo/api/dataSets//dataElements/#{id}")
        .to_return(status: 200, body: "", headers: {})
    end
  end

  describe "for newer synchro" do
    let(:project) { full_project }

    let(:expected_data_element_group) do
      { "name":         "ORBF - Quantity PMA",
        "shortName":    "ORBF-Quantity PMA",
        "code":         "ORBF-Quantity PMA",
        "dataElements": [
          { "id": "cl-ext-2" },
          { "id": "tarif-ext-2" },
          { "id": "tarif-ext-1" },
          { "id": "clext1" }
        ]
      }
    end

    let(:existing_data_element_group) do
      expected_data_element_group.merge("id"=> "dhis2DEGID")
    end

    def stub_indicators
      stub_request(:get, "http://play.dhis2.org/demo/api/indicators?fields=id,name,numerator&pageSize=50000").to_return(status: 200, body: fixture_content(:dhis2, "one_indicator.json"))
    end

    def stub_data_element_group_creation
      stub_request(:post, "http://play.dhis2.org/demo/api/metadata")
        .with(
          body: JSON.generate("dataElementGroups": [expected_data_element_group])
        ).to_return(status: 200, body: "")
    end

    def stub_data_element_group_get
      stub_request(:get, "http://play.dhis2.org/demo/api/dataElementGroups?fields=:all&filter=name:eq:ORBF%20-%20Quantity%20PMA")
        .to_return(status: 200, body: JSON.generate("dataElementGroups": [existing_data_element_group]))
    end

    it "should create" do
      # minimize the number of stub to first package
      project.payment_rules.destroy_all
      project.packages[1..-1].map(&:destroy)
      # make sure to have at least one indicator
      project.packages.first.activities.first.activity_states.first.update(kind: "indicator", external_reference: "indicator-dhis-id")

      stub_indicators
      stub_data_element_group_creation
      stub_data_element_group_get

      SynchroniseDegDsWorker.new.perform(project.project_anchor.id)

      project.reload # to make sure the package is reloaded
      expect(project.packages.first.deg_external_reference).to eq("dhis2DEGID")
    end
  end
end
