require "rails_helper"

describe Invoicing::InvoiceEntity do
  include_context "basic_context"

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

    it 'sends values without feature enabled' do
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }]*1001)
      stub_request(:any, expected_url).to_return(body: success_response.to_json)

      expect{ entity.publish_to_dhis2 }.to change{Dhis2Log.count}.by(1)
      expect(a_request(:post, expected_url)).to have_been_made.times(1)
    end

    it 'sends values with feature enabled' do
      Flipper[:use_parallel_publishing].enable(project.project_anchor)
      entity.instance_variable_set(:@dhis2_export_values, [{ value: 1234 }]*1001)
      stub_request(:any, expected_url).to_return(body: success_response.to_json)

      expect{ entity.publish_to_dhis2 }.to change{Dhis2Log.count}.by(1)
      expect(a_request(:post, expected_url)).to have_been_made.times(2)
    end
  end
end
