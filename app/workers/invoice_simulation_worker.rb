require "invoice_entity_to_json"
# frozen_string_literal: true

class InvoiceSimulationWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle(
    concurrency: { limit: 3 },
    key_suffix:  ->(project_anchor_id, _year, _quarter, _selected_org_unit_ids = nil, _options = {}) { project_anchor_id }
  )

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

  def perform(project_id, entity, period, engine_version, with_details, simulate_draft)
    InvoicingJob.execute(project_anchor, "#{year}Q#{quarter}", selected_org_unit_ids&.first) do
      request = InvoicingRequest.new(year: year, quarter: quarter)

      project = project_anchor.projects.for_date(request.end_date_as_date) || project_anchor.latest_draft
      request.engine_version = project.engine_version

      if project.new_engine? && selected_org_unit_ids.size == 1
        options = Invoicing::InvoicingOptions.new(
          publish_to_dhis2:       true,
          force_project_id:       nil,
          allow_fresh_dhis2_data: false
        )
        request.entity = selected_org_unit_ids.first
        invoice_entity = Invoicing::InvoiceEntity.new(project_anchor, request, options)
        invoice_entity.call
      else
        contracted_entities = organisation_units(project_anchor, request)
        contracted_entities &= selected_org_unit_ids if selected_org_unit_ids

        Rails.logger.info "contracted_entities #{contracted_entities.size}"
        if contracted_entities.empty?
          Rails.logger.info("WARN : selected_org_unit_ids '#{selected_org_unit_ids}'"\
            " aren't in the contracted group !")
        end

        contracted_entities.each_slice(options[:slice_size]).each do |org_unit_ids|
          # currently not doing it async but might be needed
          InvoicesForEntitiesWorker.new.perform(project_anchor_id, year, quarter, org_unit_ids, options)
        end
      end
    end
  end
end
