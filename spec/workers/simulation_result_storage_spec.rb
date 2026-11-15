# frozen_string_literal: true

require "rails_helper"

# Simulation results live on S3 (production) or MinIO (local hosting): the worker stores them
# gzipped with the S3 client, the manager downloads them through InvoicingJob#result_url.
# The other specs mock S3, this one goes through a real S3 api: it only runs when
# S3_SIMULATION_ENDPOINT points to one (CI and docker-compose.test.yml start a MinIO).
RSpec.describe "Simulation result storage" do
  endpoint = ENV["S3_SIMULATION_ENDPOINT"].presence

  before { skip "S3_SIMULATION_ENDPOINT not set (needs a MinIO, see docker-compose.test.yml)" unless endpoint }

  let(:service) { ActiveStorage::Blob.services.fetch(:minio) }
  let(:json) { { "invoices" => [{ "code" => "quantity", "total" => 42.5 }] }.to_json }

  around do |example|
    default_service = ActiveStorage::Blob.service
    if endpoint
      ActiveStorage::Blob.service = service
      WebMock.disable_net_connect!(allow: URI(endpoint).authority)
    end
    example.run
  ensure
    ActiveStorage::Blob.service = default_service
    WebMock.disable_net_connect!
  end

  before do
    next unless endpoint

    service.client.client.create_bucket(bucket: service.bucket.name) unless service.bucket.exists?
  end

  def download(url)
    uri = URI(url)
    # ask for gzip ourselves so Net::HTTP keeps the body and the Content-Encoding as sent
    Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.request_uri, "Accept-Encoding" => "gzip") }
  end

  it "stores the result gzipped and serves it as inline json through result_url" do
    job = FactoryBot.create(:invoicing_simulation_job)
    blob = InvoiceSimulationWorker.new.send(:uploaded_blob, "simulation-#{job.id}.json", json)
    job.result.attach(blob)

    response = download(job.reload.result_url)

    expect(response.code).to eq("200"), "#{response.code} #{response.body}"
    expect(response["Content-Type"]).to eq("application/json")
    expect(response["Content-Encoding"]).to eq("gzip")
    expect(response["Content-Disposition"]).to start_with("inline")
    expect(Zlib.gunzip(response.body)).to eq(json)
  end

  it "records the checksum and size of what was uploaded" do
    blob = InvoiceSimulationWorker.new.send(:uploaded_blob, "simulation.json", json)

    expect(blob.reload).to have_attributes(service_name: "minio", content_type: "application/json")
    expect(blob.byte_size).to eq(service.bucket.object(blob.key).content_length)
    # open verifies the checksum against the stored object
    blob.open { |file| expect(Zlib.gunzip(file.read)).to eq(json) }
  end
end
