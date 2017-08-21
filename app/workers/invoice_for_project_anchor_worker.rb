
class InvoiceForProjectAnchorWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, year, quarter, selected_org_unit_ids = nil, options = {})
    default_options = {
      slice_size: 25
    }

    options = default_options.merge(options)
    project_anchor = ProjectAnchor.find(project_anchor_id)

    request = InvoicingRequest.new(year: year, quarter: quarter)
    contracted_entities = organisation_units(project_anchor, request)
    contracted_entities &= selected_org_unit_ids if selected_org_unit_ids

    puts "contracted_entities #{contracted_entities.size}"    
    if contracted_entities.empty?
      puts "WARN : selected_org_unit_ids #{selected_org_unit_ids} are in the contracted group !"
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
      puts "quarter_date #{quarter_date.year}-#{quarter_date.month} => projects #{project.status} #{project.id} => #{contracted_entities.size} (#{project.entity_group.external_reference})"
      contracted_entities.map(&:id)
    end.flatten.uniq.sort
  end
end
