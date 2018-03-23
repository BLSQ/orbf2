require "rails_helper"

RSpec.describe SynchroniseDegDsWorker do
  include_context "basic_context"
  let(:project) {
    full_project.payment_rules.destroy_all
    full_project.payment_rules.destroy_all
    full_project.packages.each_with_index do |package, index|
      package.destroy if index > 0
    end
    full_project.packages.reload
    full_project
  }

  let(:all_dataset) do
    []
  end

  DS_CLAIMED = "{\"code\":\"claimed-Quantity PMA\",\"periodType\":\"Monthly\",\"name\":\"Claimeds - Quantity PMA\",\"shortName\":\"claimed-Quantity PMA\",\"displayName\":\"Claimeds - Quantity PMA\",\"dataElements\":[{\"id\":\"cl-ext-1\"},{\"id\":\"cl-ext-2\"}],\"dataSetElements\":[{\"dataElement\":{\"id\":\"cl-ext-1\"}},{\"dataElement\":{\"id\":\"cl-ext-2\"}}]}".freeze
  DS_CLAIMED_ID = "VWUA11GeMwn".freeze

  DS_TARIF = "{\"code\":\"tarif-Quantity PMA\",\"periodType\":\"Monthly\",\"name\":\"Tarifs - Quantity PMA\",\"shortName\":\"tarif-Quantity PMA\",\"displayName\":\"Tarifs - Quantity PMA\",\"dataElements\":[{\"id\":\"tarif-ext-1\"},{\"id\":\"tarif-ext-2\"}],\"dataSetElements\":[{\"dataElement\":{\"id\":\"tarif-ext-1\"}},{\"dataElement\":{\"id\":\"tarif-ext-2\"}}]}".freeze
  DS_TARIF_ID = "sdfsdf546".freeze

  it "should create" do
    stub_all_indicators
    stub_category_combos

    stub_dataset(DS_CLAIMED_ID, DS_CLAIMED, ["cl-ext-1", "cl-ext-2"])
    stub_dataset(DS_TARIF_ID, DS_TARIF, ["tarif-ext-1", "tarif-ext-2"])

    stub_request(:get, "http://play.dhis2.org/demo/api/dataSets/#{DS_TARIF_ID}")
      .to_return(status: 200, body: DS_TARIF)

    SynchroniseDegDsWorker.new.perform(project.project_anchor.id)
  end

  def stub_dataset(dataset_id, dataset, data_element_ids)
    stub_dataset_creation(dataset, dataset_id)
    data_element_ids.each do |de_id|
      stub_data_elements_in_dataset(dataset_id, de_id)
    end
    stub_request(:get, "http://play.dhis2.org/demo/api/dataSets/#{dataset_id}")
      .to_return(status: 200, body: dataset)
  end

  def stub_dataset_creation(ds_string, uuid)
    response = {
      "responseType" => "ImportTypeSummary",
      "status"       => "OK",
      "stats"        => { "imported" => 1, "updated" => 0, "deleted" => 0, "ignored" => 0, "total" => 1 },
      "type"         => "DataSet",
      "lastImported" => "uuid",
      "response"     => {
        "responseType"=> "ImportTypeSummary",
        "status"=>       "SUCCESS",
        "importCount"=>  {
          "imported" => 1,
          "updated"  => 0,
          "ignored"  => 0,
          "deleted"  => 0
        },
        "type"=>         "DataSet",
        "lastImported": uuid
      }
    }

    stub_request(:post, "http://play.dhis2.org/demo/api/dataSets")
      .with(body: ds_string).to_return(status: 200, body: response.to_json)
  end

  def stub_all_indicators
    stub_request(:get, "#{project.dhis2_url}/api/indicators?fields=:all&page=1")
      .to_return(status: 200, body: fixture_content(:dhis2, "indicators.json"))
  end

  def stub_update_data_element_sets
    stub_request(:put, "http://play.dhis2.org/demo/api/dataSets/")
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_category_combos
    stub_request(:get, "http://play.dhis2.org/demo/api/categoryCombos?fields=:all&filter=name:eq:default")
      .to_return(status: 200, body: fixture_content(:dhis2, "category_combos.json"))
  end

  def stub_data_elements_in_dataset(ds_id, id)
    stub_request(:post, "http://play.dhis2.org/demo/api/dataSets/#{ds_id}/dataElements/#{id}")
      .to_return(status: 200, body: "", headers: {})
  end
end
