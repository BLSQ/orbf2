# frozen_string_literal: true

class InvoiceForProjectAnchorWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

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
        raise "TODO : no more supported"
      end
    end
  end

  def organisation_units(project_anchor, request)
    request.quarter_dates.map do |quarter_date|
      pyramid = project_anchor.nearest_pyramid_for(quarter_date)
      project = project_anchor.projects.for_date(quarter_date) || project_anchor.latest_draft
      contracted_entities = pyramid.org_units_in_all_groups([project.entity_group.external_reference])
      Rails.logger.info "quarter_date #{quarter_date.year}-#{quarter_date.month} => projects #{project.status} #{project.id} => #{contracted_entities.size} (#{project.entity_group.external_reference})"
      contracted_entities.map(&:id)
    end.flatten.uniq.sort
  end
end
