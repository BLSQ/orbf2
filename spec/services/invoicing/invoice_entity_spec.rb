# frozen_string_literal: true

require "rails_helper"
require_relative "../../workers/dhis2_snapshot_fixture"

describe Invoicing::InvoiceEntity do
  include_context "basic_context"
  include Dhis2SnapshotFixture

  let(:conflicts_reponse) {
    {
      "status":            "WARNING",
      "conflicts":         [
        {
          "value":  "Data is already approved for data set: TsLR0wQJknp period: 201903 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0",
          "object": "iA3y8AyMTG2"
        },
        {
          "value":  "Data is already approved for data set: TsLR0wQJknp period: 201902 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0",
          "object": "iA3y8AyMTG2"
        },
        {
          "value":  "Data is already approved for data set: TsLR0wQJknp period: 201901 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0",
          "object": "iA3y8AyMTG2"
        }
      ],
      "description":       "Import process completed successfully",
      "import_count":      {
        "deleted":  0,
        "ignored":  3,
        "updated":  0,
        "imported": 1
      },
      "response_type":     "ImportSummary",
      "import_options":    {
        "async":                          false,
        "force":                          false,
        "dry_run":                        false,
        "sharing":                        false,
        "id_schemes":                     {
        },
        "merge_mode":                     "REPLACE",
        "skip_audit":                     false,
        "report_mode":                    "FULL",
        "strict_periods":                 false,
        "import_strategy":                "CREATE_AND_UPDATE",
        "skip_last_updated":              false,
        "skip_notifications":             false,
        "first_row_is_header":            true,
        "skip_existing_check":            false,
        "strict_data_elements":           false,
        "dataset_allows_periods":         false,
        "ignore_empty_collection":        false,
        "skip_pattern_validation":        false,
        "strict_organisation_units":      false,
        "require_category_option_combo":  false,
        "strict_category_option_combos":  false,
        "require_attribute_option_combo": false,
        "strict_attribute_option_combos": false
      },
      "data_set_complete": "false"
    }
  }

  describe "use_parallel_publishing" do
    let(:project) { full_project }
    let(:expected_url) { "http://play.dhis2.org/demo/api/dataValueSets" }
    let(:entity) {
      entity = Invoicing::InvoiceEntity.new(project.project_anchor, nil, nil)
    }

    let(:success_response) {
      {
        "status"            => "SUCCESS",
        "description"       => "My own special description",
        "import_count"      => { "deleted": 0, "ignored": 0, "updated": 0, "imported": 1 },
        "response_type"     => "ImportSummary",
        "import_options"    => { some: "data", with: "keys", more: "data" },
        "data_set_complete" => false
      }
    }

    it "sends values without feature enabled to a dhis2 < 2.38" do
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }] * 1001)
      stub_request(:any, expected_url).to_return(body: success_response.to_json)

      expect { entity.publish_to_dhis2 }.to change { Dhis2Log.count }.by(1)
      expect(a_request(:post, expected_url)).to have_been_made.times(1)
    end

    it "sends values without feature enabled to a dhis2 >= 2.38" do
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }] * 1001)
      stub_request(:any, expected_url).to_return(
        status: 200,
        body:   {
          "httpStatus":     "OK",
          "httpStatusCode": 200,
          "status":         "OK",
          "message":        "Import was successful.",
          "response":       success_response
        }.to_json
      )

      expect { entity.publish_to_dhis2 }.to change { Dhis2Log.count }.by(1)
      expect(a_request(:post, expected_url)).to have_been_made.times(1)
    end

    it "sends locked values without feature enabled to a dhis2 < 2.38" do
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }] * 1001)
      stub_request(:any, expected_url).to_return(body: conflicts_reponse.to_json)

      expect { entity.publish_to_dhis2 }.to raise_error(
        Invoicing::PublishingError,
        "Data is already approved for data set: TsLR0wQJknp period: 201903 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0, Data is already approved for data set: TsLR0wQJknp period: 201902 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0, Data is already approved for data set: TsLR0wQJknp period: 201901 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0"
      )
    end

    it "sends locked values without feature enabled to a dhis2 >= 2.38" do
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }] * 1001)
      stub_request(:any, expected_url).to_return(status: 409, body:  {
        "httpStatus":     "Conflict",
        "httpStatusCode": 409,
        "status":         "WARNING",
        "message":        "One more conflicts encountered, please check import summary.",
        "response":       conflicts_reponse
      }.to_json)

      expect { entity.publish_to_dhis2 }.to raise_error(
        Invoicing::PublishingError,
        "Data is already approved for data set: TsLR0wQJknp period: 201903 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0, Data is already approved for data set: TsLR0wQJknp period: 201902 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0, Data is already approved for data set: TsLR0wQJknp period: 201901 organisation unit: iA3y8AyMTG2 attribute option combo: HllvX50cXC0"
      )
    end

    it "sends values with feature enabled" do
      Flipper[:use_parallel_publishing].enable(project.project_anchor)
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }] * 1001)
      stub_request(:any, expected_url).to_return(body: success_response.to_json)

      expect { entity.publish_to_dhis2 }.to change { Dhis2Log.count }.by(1)
      expect(a_request(:post, expected_url)).to have_been_made.times(2)
    end
  end

  describe "contract based project" do
    let(:project) { full_project }
    let(:expected_url) { "http://play.dhis2.org/demo/api/dataValueSets" }

    let(:invoicing_request) {
      InvoicingRequest.new(
        entity:         "Rp268JB6Ne4",
        year:           2020,
        quarter:        1,
        engine_version: 3
      )
    }
    let(:entity) {
      entity = Invoicing::InvoiceEntity.new(project.project_anchor, invoicing_request, nil)
    }

    it "sends values with feature enabled" do
      stub_snapshots(project)

      project.entity_group.update(kind: "contract_program_based", program_reference: "contractprogid", all_event_sql_view_reference: "sqlviewid")

      stub1 = stub_request(:get, "http://play.dhis2.org/demo/api/sqlViews/sqlviewid/data.json?paging=false&var=programId:contractprogid").to_return(status: 200, body: fixture_content(:dhis2, "contracts_events.json"))
      stub2 = stub_request(:get, "http://play.dhis2.org/demo/api/programs/contractprogid?fields=id,name,programStages%5BprogramStageDataElements%5BdataElement%5Bid,name,code,optionSet%5Bid,name,code,options%5Bid,code,name%5D%5D%5D%5D&paging=false").to_return(status: 200, body: fixture_content(:dhis2, "contracts_program.json"))

      # no stub on push expect no dhis2

      expect { entity.call }.to change { Dhis2Log.count }.by(0)

      expect(stub1).to have_been_requested
      expect(stub2).to have_been_requested
    end
  end
end
