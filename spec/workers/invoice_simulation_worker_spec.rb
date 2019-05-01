# frozen_string_literal: true

require "fileutils"

require "rails_helper"

require_relative "./project_fixture"

RSpec.describe InvoiceSimulationWorker do
  include ProjectFixture
  ORG_UNIT_ID = "vRC0stJ5y9Q"
  include_context "basic_context"

  let(:program) { create :program }

  let!(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program
    project.payment_rules.each { |p| p.update(frequency: "quarterly") }
    project.packages.each { |p| p.update(frequency: "quarterly") }

    with_activities_and_formula_mappings(project)
    create_snaphots(project)
    with_latest_engine(project)
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!
    project
  end
  let(:worker) { described_class.new }

  it "works for non contracted but shows a warning" do
    project.entity_group.external_reference = "external_reference"
    project.entity_group.save!
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&orgUnit=#{ORG_UNIT_ID}&period=2015Q1")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": generate_quarterly_values_for(project)))

    simulation_json = with_mocked_s3 do
      worker.perform(ORG_UNIT_ID, "2015Q1", project.id, true, 3, true)
    end

    expect(simulation_json["request"]["warnings"]).to eq(
      "Entity is not in the contracted entity group : Clinic. "\
      "(Snaphots last updated on #{Time.now.to_date}). Only simulation will work. "\
      "Update the group and trigger a dhis2 snaphots. "\
      "Note that it will only fix this issue for current or futur periods."
    )
  end

  it "stores exception message when dhis2 is not available" do
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&orgUnit=#{ORG_UNIT_ID}&period=2015Q1")
      .to_return(status: 503, body: "")

    with_mocked_s3 do
      begin
        worker.perform(ORG_UNIT_ID, "2015Q1", project.id, true, 3, true)
      rescue InvoiceSimulationWorker::Simulation::ErrorDuringSimulation => _ignored
      end
    end

    expect(InvoicingSimulationJob.last.last_error).to eq("InvoiceSimulationWorker::Simulation::ErrorDuringSimulation: 503 Service Unavailable")
  end

  it "stores exception message when there's problem with formula evaluation" do
    project.packages.first.activity_rule.formula("amount").update(expression: "tarif / 0")

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&orgUnit=#{ORG_UNIT_ID}&period=2015Q1")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": generate_quarterly_values_for(project)))

    with_mocked_s3 do
      begin
        worker.perform(ORG_UNIT_ID, "2015Q1", project.id, false, 3, true)
      rescue InvoiceSimulationWorker::Simulation::ErrorDuringSimulation => _ignored
      end
    end

    expect(InvoicingSimulationJob.last.last_error).to eq("InvoiceSimulationWorker::Simulation::ErrorDuringSimulation: "\
      "In equation quantity_pma_clients_sous_traitement_arv_suivi_pendant_les_6_premiers_mois_amount_for_vRC0stJ5y9Q_and_2015q1 "\
      "Divide by zero quantity_pma_clients_sous_traitement_arv_suivi_pendant_les_6_premiers_mois_amount_for_vRC0stJ5y9Q_and_2015q1 "\
      ":= quantity_pma_clients_sous_traitement_arv_suivi_pendant_les_6_premiers_mois_tarif_for_vRC0stJ5y9Q_and_2015q1 / 0")
  end

  # double to mock s3 related calls
  let(:active_storage_client) { double("active_storage_client") }
  let(:s3_bucket) { double("simulation_bucket") }
  let(:s3_bucket_client) { double("s3_bucket_client") }

  # mock some specific s3 and return the simulation job json if simulation is successful
  def with_mocked_s3
    # as we couldn't use the default s3 active storage to store gzipped json
    # the production code is assuming some s3 dependencies (service and bucket)
    # that are not provided by the non-s3 ActiveStorage::Service::DiskService
    # so we mock them
    asc = active_storage_client
    bucket = s3_bucket
    ActiveStorage::Blob.service.define_singleton_method(:client) { asc }
    ActiveStorage::Blob.service.define_singleton_method(:bucket) { bucket }

    # expect object lookup by blob key
    # and at the sametime store the expected path by ActiveStorage::Service::DiskService
    # for the "put"
    file_path = nil
    allow(bucket).to receive(:object) { |spy_blob_key|
      path = ActiveStorage::Blob.service.send(:path_for, spy_blob_key)
      file_path = path
      s3_bucket_client
    }

    # store the file in binary mode (gzip json)
    allow(s3_bucket_client).to receive(:put) { |args|
      dirname = File.dirname(file_path)
      puts "****************** \n"+dirname+"****************** "
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      File.open(file_path, "w") { |file|
        file.binmode
        file.write(args[:body].read)
      }
    }

    # yield the block to trigger the simulation with desired options
    # allow also rescuing some expected exception
    yield

    # load, unzip and parse the file (if one was generated)
    if file_path
      data = Zlib::GzipReader.open(file_path, &:read)
      File.delete(file_path)
      JSON.parse(data)
    end
  end
end
