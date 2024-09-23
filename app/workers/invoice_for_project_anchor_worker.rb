# frozen_string_literal: true

class InvoiceForProjectAnchorWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options(
    retry: 11 # around 7h max in the queue
  )

  sidekiq_throttle(
    concurrency: {
      limit: ENV.fetch("SDKQ_MAX_CONCURRENT_INVOICE", 3).to_i,
      ttl:   ENV.fetch("SDKQ_MAX_TTL_INVOICE", 1.hour.to_i).to_i
    },
    key_suffix:  lambda { |project_anchor_id, _year, _quarter, _selected_org_unit_ids = nil, _options = {}|
      per_process_id = ENV.fetch("HEROKU_DYNO_ID", $PROCESS_ID)
      [project_anchor_id, per_process_id].join("-")
    }
  )

  def perform(project_anchor_id, year, quarter, selected_org_unit_ids = nil, options = {})
    if ENV.fetch("SDKQ_FORK_ENABLED", "false") == "true"
      command = "time bundle exec rails runner 'InvoiceForProjectAnchorWorker.new.really_perform(#{project_anchor_id}, #{year}, #{quarter}, [\"" + selected_org_unit_ids[0] + "\"])'"
      puts("forking invoice", command)
      puts(exec(command))
    else
      really_perform(project_anchor_id, year, quarter, selected_org_unit_ids, options)
    end
  end

  def really_perform(project_anchor_id, year, quarter, selected_org_unit_ids = nil, options = {})
    default_options = {
      slice_size: 25
    }
    if selected_org_unit_ids.nil? || selected_org_unit_ids.size > 1
      raise "no more supported : should provide an single selected_org_unit_ids "
    end

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
