# frozen_string_literal: true

class InvoiceForProjectAnchorWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options(
    retry: 11 # around 7h max in the queue
  )

  sidekiq_throttle(
    concurrency: { limit: ENV.fetch("SDKQ_MAX_CONCURRENT_INVOICE", 3).to_i },
    key_suffix:  ->(project_anchor_id, _year, _quarter, _selected_org_unit_ids = nil, _options = {}) { project_anchor_id }
  )

  def perform(project_anchor_id, year, quarter, selected_org_unit_ids = nil, options = {})
    default_options = {
      slice_size: 25
    }
    raise "no more supported : should provide an single selected_org_unit_ids " if selected_org_unit_ids.nil? || selected_org_unit_ids.size > 1

    options = default_options.merge(options)
    project_anchor = ProjectAnchor.find(project_anchor_id)
    InvoicingJob.execute(project_anchor, "#{year}Q#{quarter}", selected_org_unit_ids&.first) do |invoicing_job|
      request = InvoicingRequest.new(year: year, quarter: quarter)

      project = project_anchor.projects.for_date(request.end_date_as_date) || project_anchor.latest_draft
      request.engine_version = project.engine_version

      options = Invoicing::InvoicingOptions.new(
        publish_to_dhis2:       true,
        force_project_id:       nil,
        allow_fresh_dhis2_data: false,
        invoicing_job:          invoicing_job,
        sidekiq_job_ref:        jid
      )
      request.entity = selected_org_unit_ids.first
      invoice_entity = Invoicing::InvoiceEntity.new(project_anchor, request, options)
      invoice_entity.call
    end
  rescue Invoicing::PublishingError => e
    puts "job failed #{e.message} : #{project_anchor}, #{year}Q#{quarter} #{selected_org_unit_ids}"
  rescue Hesabu::Error => e
    if e.message =~ /In equation/
    # The job won't magically heal itself, since the equation
    # can't compute. This way we keep our queue clean.
    else
      raise e
    end
  end
end
