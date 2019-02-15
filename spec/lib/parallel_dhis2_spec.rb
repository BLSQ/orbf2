# frozen_string_literal: true

require "rails_helper"

def dhis2_client(options = {})
  default_options = {
    url:      "https://play.dhis2.org/demo",
    user:     "admin",
    password: "district",
    debug:    true
  }
  options = default_options.merge(options)
  Dhis2::Client.new(options)
end

def fake_response(status:, conflicts: nil, description: "", import_count: {})
  response = {
    "status"            => status,
    "description"       => description,
    "import_count"      => import_count,
    "response_type"     => "ImportSummary",
    "import_options"    => { some: "data", with: "keys", more: "data" },
    "data_set_complete" => false
  }
  response.merge!("conflicts" => conflicts) if conflicts
  response
end

RSpec.describe ParallelDhis2 do
  it "#prepare_payload" do
    parallel_dhis2 = described_class.new(dhis2_client)
    prepared_payload = parallel_dhis2.prepare_payload(
      [{ "my_key": 1 }, { "my_other_key": 15 }]
    )
    expect(prepared_payload).to eq("[{\"myKey\":1},{\"myOtherKey\":15}]")
  end

  describe "build_post_request" do
    let(:payload) {
      [{ "my_key": 1 }, { "my_other_key": 15 }]
    }
    let(:client) {
      described_class.new(dhis2_client(timeout: 1234))
    }
    let(:request) {
      client.build_post_request("http://something.example", payload)
    }
    it "sets headers" do
      expect(request.options[:headers]).to include("Accept" => "json", "Content-Type" => "application/json")
    end

    it "sets ssl" do
      expect(request.options[:ssl_verifypeer]).to eq(true)
    end

    it "sets timeout" do
      expect(request.options[:timeout]).to eq(1234)
    end

    it "transforms body" do
      expect(request.encoded_body).to eq(client.prepare_payload(payload))
    end
  end

  describe "post_data_value_sets" do
    let(:expected_url) { "https://play.dhis2.org/demo/api/dataValueSets" }
    let(:client) {
      described_class.new(dhis2_client(debug: false))
    }

    it "parallelizes on SEND_VALUES_PER" do
      payload = fake_response(
        status:       "SUCCESS",
        description:  "Import process completed successfully",
        import_count: { "deleted": 10, "ignored": 20, "updated": 30, "imported": 40 }
      )
      faked_response = Dhis2::Case.deep_change(payload, :camelize)
      stub_request(:any, expected_url).to_return(body: faked_response.to_json)
      number_of_times = 3
      all_values = [{ value: 1234 }] * ParallelDhis2::SEND_VALUES_PER * number_of_times
      client.post_data_value_sets(all_values)
      expect(a_request(:post, expected_url)).to have_been_made.times(number_of_times)
    end

    it "raises on time out" do
      stub_request(:any, expected_url).to_timeout
      all_values = [{ value: 1234 }]
      expect {
        client.post_data_value_sets(all_values)
      }.to raise_error ParallelDhis2::TimedOut
    end

    it "raises on 500" do
      stub_request(:any, expected_url).to_return(status: [500, "Internal Server Error"])
      all_values = [{ value: 1234 }]
      expect {
        client.post_data_value_sets(all_values)
      }.to raise_error ParallelDhis2::HttpException
    end

    it "returns a Dhis2::Status" do
      payload = fake_response(
        status:       "SUCCESS",
        description:  "Import process completed successfully",
        import_count: { "deleted": 10, "ignored": 20, "updated": 30, "imported": 40 }
      )
      faked_response = Dhis2::Case.deep_change(payload, :camelize)
      stub_request(:any, expected_url).to_return(body: faked_response.to_json)
      all_values = [{ value: 1234 }]
      status = client.post_data_value_sets(all_values)
      expect(status).to be_kind_of(Dhis2::Status)
      expect(status.success?).to eq(true)
    end
  end

  describe ParallelDhis2::RollUpResponses do
    let(:failed_response) {
      fake_response(status:       "ERROR",
                    conflicts:    [
                      { value: "This", object: "123" },
                      { value: "Other", object: "254" }
                    ],
                    description:  "The import process failed: Failed to update object",
                    import_count: { "deleted": 0, "ignored": 0, "updated": 0, "imported": 0 })
    }
    let(:warning_response) {
      fake_response(status:       "WARNING",
                    conflicts:    [
                      { value: "This", object: "123" },
                      { value: "Other", object: "254" }
                    ],
                    description:  "Import process completed successfully",
                    import_count: { "deleted": 1, "ignored": 2, "updated": 3, "imported": 4 })
    }
    let(:weird_response) {
      fake_response(status: "WEIRD")
    }
    let(:success_response) {
      fake_response(status:       "SUCCESS",
                    description:  "Import process completed successfully",
                    import_count: { "deleted": 10, "ignored": 20, "updated": 30, "imported": 40 })
    }

    describe "#call" do
      describe "with mixed results" do
        subject(:rolled_up) { described_class.new([failed_response, warning_response, success_response]).call }

        it(:status) { expect(rolled_up["status"]).to eq("ERROR") }
        it(:conflicts) { expect(rolled_up["conflicts"].count).to eq(2 + 2 + 0) }
        it(:description) { expect(rolled_up["description"]).to eq("The import process failed: Failed to update object && Import process completed successfully [parallel]") }
        it(:import_count) { expect(rolled_up["import_count"]).to eq(deleted: 11, ignored: 22, updated: 33, imported: 44) }
        it(:import_options) { expect(rolled_up["import_options"].count).to eq(3) }
        it(:data_set_complete) { expect(rolled_up["data_set_complete"]).to eq(false) }
      end

      describe "with only successes" do
        subject(:rolled_up) { described_class.new([success_response]*5).call }

        it(:status) { expect(rolled_up["status"]).to eq("SUCCESS") }
        it(:conflicts) { expect(rolled_up).to_not have_key("conflicts") }
        it(:description) { expect(rolled_up["description"]).to eq("Import process completed successfully [parallel]") }
        it(:import_count) { expect(rolled_up["import_count"]).to eq(deleted: 5*10, ignored: 5*20, updated: 5*30, imported: 5*40) }
        it(:import_options) { expect(rolled_up["import_options"].count).to eq(5) }
        it(:data_set_complete) { expect(rolled_up["data_set_complete"]).to eq(false) }
      end
    end

    describe "#status" do
      it "is error if any is error" do
        roller = described_class.new([failed_response, warning_response, success_response])
        expect(roller.status).to eq(described_class::ERROR)
      end

      it "is warning if no errors and any is warning" do
        roller = described_class.new([warning_response, success_response])
        expect(roller.status).to eq(described_class::WARNING)
      end

      it "is success if no errors and no warnings" do
        roller = described_class.new([success_response, success_response])
        expect(roller.status).to eq(described_class::SUCCESS)
      end

      it "defaults to ERROR when unknown status" do
        roller = described_class.new([fake_response(status: "WEIRD")])
        expect(roller.status).to eq(described_class::ERROR)
      end
    end

    describe "#import_count" do
      it "sums everything" do
        roller = described_class.new([failed_response,
                                      weird_response,
                                      warning_response,
                                      success_response])
        expect(roller.import_count[:deleted]).to eq(0 + 1 + 10)
        expect(roller.import_count[:ignored]).to eq(0 + 2 + 20)
        expect(roller.import_count[:updated]).to eq(0 + 3 + 30)
        expect(roller.import_count[:imported]).to eq(0 + 4 + 40)
      end
    end
  end

  describe ParallelDhis2::ClientWrapper do
    describe "#base_url" do
      it "returns authenticated URL" do
        client = described_class.new(dhis2_client)
        expect(client.base_url).to eq("https://admin:district@play.dhis2.org/demo")
      end

      it "breaks if accessor is available" do
        raise "Use accessor instead of instance variable" if dhis2_client.respond_to?(:base_url)
      end
    end

    describe "#verify_ssl_settings" do
      it "verify_none when SSL disabled" do
        client_without_ssl = described_class.new(dhis2_client(no_ssl_verification: true))
        expect(client_without_ssl.verify_ssl_settings).to eq(OpenSSL::SSL::VERIFY_NONE)
      end

      it "verify_peer when SSL disabled" do
        client_with_ssl = described_class.new(dhis2_client)
        expect(client_with_ssl.verify_ssl_settings).to eq(OpenSSL::SSL::VERIFY_PEER)
      end

      it "breaks if accessor is available" do
        raise "Use accessor instead of instance variable" if dhis2_client.respond_to?(:verify_ssl)
      end
    end

    describe "#time_out_settings" do
      it "returns timeout when set" do
        client = described_class.new(dhis2_client(timeout: 1234))
        expect(client.time_out_settings).to eq(1234)
      end

      it "returns default timeout" do
        client = described_class.new(dhis2_client)
        expect(client.time_out_settings).to eq(120)
      end

      it "breaks if accessor is available" do
        raise "Use accessor instead of instance variable" if dhis2_client.respond_to?(:timeout)
      end
    end

    it "#post_headers" do
      client = described_class.new(dhis2_client)
      expect(client.post_headers).to eq("Accept" => "json", "Content-Type" => "application/json")
    end

    it "#user" do
      client = described_class.new(dhis2_client)
      expect(client.user).to eq("admin")
    end

    it "#password" do
      client = described_class.new(dhis2_client)
      expect(client.password).to eq("district")
    end

    describe "#url" do
      let(:client) { described_class.new(dhis2_client) }

      it { expect(client.url).to eq("https://play.dhis2.org/demo") }
      it { expect(client.url).to_not include("admin") }
      it { expect(client.url).to_not include("district") }
    end

    describe "#debug?" do
      it do
        expect(described_class.new(dhis2_client(debug: true)).debug?).to eq(true)
      end
      it do
        expect(described_class.new(dhis2_client(debug: false)).debug?).to eq(false)
      end
    end
  end
end
