require "invoice_entity_to_json"
# frozen_string_literal: true

class InvoiceSimulationWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle(
    concurrency: { limit: 3 },
    key_suffix:  ->(entity, period, project_id, with_details, engine_version, simulate_draft) { project_id }
  )

  def perform(entity, period, project_id, with_details, engine_version, simulate_draft)
    project = Project.find(project_id)
    InvoicingSimulationJob.execute(project.project_anchor, period, entity) do |job|
      serialized_json = InvoiceSimulationWorker::Simulation.new(entity, period, project_id, engine_version, with_details, simulate_draft).call

      if job
        name = "%s.json" % [project_id.to_s, entity, period].map(&:underscore).join("-")
        active_storage_blob = uploaded_blob(name, serialized_json)
        job.result.attach(active_storage_blob)
      end
    end
  end

  def uploaded_blob(name, serialized_json)
    gzipped = gzip(serialized_json)
    s3_client = ActiveStorage::Blob.service.client
    bucket = ActiveStorage::Blob.service.bucket
    blob = ActiveStorage::Blob.new
    io = StringIO.new(gzipped)
    blob.filename = name
    blob.checksum = blob.send(:compute_checksum_in_chunks, io)
    blob.byte_size = io.size
    blob.content_type = "application/json"

    bucket.object(blob.key).put(body: io, content_type: "application/json", content_encoding: "gzip")
    blob.save
    blob
  end

  def gzip(string)
    wio = StringIO.new("w")
    w_gz = Zlib::GzipWriter.new(wio)
    w_gz.write(string)
    w_gz.close
    compressed = wio.string
  end

  class Simulation
    attr_accessor :entity, :period, :project_id, :with_details, :engine_version, :simulate_draft
    # project_id, entity, period, engine_version, with_details, simulate_draft
    def initialize(*args)
      @entity, @period, @project_id, @with_details, @engine_version, @simulate_draft = *args
    end

    def call
      # Note: Both `invoice_entity` and `invoice_request` build up
      # state here, that's why they are memoized.
      invoicing_entity.call
      indexed_project = Invoicing::IndexedProject.new(project, invoicing_entity.orbf_project)
      Invoicing::MapToInvoices.new(invoicing_request, invoicing_entity.fetch_and_solve.solver).call
      json = InvoiceEntityToJson.new(invoicing_entity).call
      json
    end

    def invoicing_entity
      @invoicing_entity ||= Invoicing::InvoiceEntity.new(project.project_anchor, invoicing_request, invoicing_options)
    end

    def invoicing_request
      @request ||= InvoicingRequest.new(
        project:        project,
        year:           year,
        quarter:        quarter,
        entity:         @entity,
        with_details:   @with_details,
        engine_version: 3 # TODO: current_project.engine_version
      )
    end

    def invoicing_options
      Invoicing::InvoicingOptions.new(
        publish_to_dhis2:       false,
        force_project_id:       simulate_draft? ? project.id : nil,
        allow_fresh_dhis2_data: simulate_draft?
      )
    end

    def simulate_draft?
      !!@simulate_draft
    end

    def year
      @period.split("Q").first
    end

    def quarter
      @period.split("Q").last
    end

    def project
      @project ||= Project.find(project_id)
    end

    def project_anchor
      @project.project_anchor
    end
  end
end
