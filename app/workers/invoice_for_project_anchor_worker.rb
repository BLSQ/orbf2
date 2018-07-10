
class InvoiceForProjectAnchorWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle(
    concurrency: { limit: 3 },
    key_suffix:  ->(project_anchor_id, _year, _quarter, _selected_org_unit_ids = nil, _options = {}) { project_anchor_id }
  )

  def perform(project_anchor_id, year, quarter, selected_org_unit_ids = nil, options = {})
    default_options = {
      slice_size: 25
    }

    options = default_options.merge(options)
    project_anchor = ProjectAnchor.find(project_anchor_id)

    request = InvoicingRequest.new(year: year, quarter: quarter)
    contracted_entities = organisation_units(project_anchor, request)
    contracted_entities &= selected_org_unit_ids if selected_org_unit_ids

    Rails.logger.info "contracted_entities #{contracted_entities.size}"
    if contracted_entities.empty?
      Rails.logger.info "WARN : selected_org_unit_ids '#{selected_org_unit_ids}' are in the contracted group !"
    end

    project = project_anchor.projects.for_date(request.end_date_as_date) || project_anchor.latest_draft
    request.engine_version = project.engine_version

    if project.new_engine? && contracted_entities.size == 1
      options = Invoicing::InvoicingOptions.new(
        publish_to_dhis2:       true,
        force_project_id:       nil,
        allow_fresh_dhis2_data: false
      )
      request.entity = contracted_entities.first
      invoice_entity = Invoicing::InvoiceEntity.new(project_anchor, request, options)
      invoice_entity.call

      return
    end

    contracted_entities.each_slice(options[:slice_size]).each do |org_unit_ids|
      # currently not doing it async but might be needed
      InvoicesForEntitiesWorker.new.perform(project_anchor_id, year, quarter, org_unit_ids, options)
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
