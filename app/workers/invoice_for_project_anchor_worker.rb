
class InvoiceForProjectAnchorWorker
  include Sidekiq::Worker

  def perform(project_anchor_id= 2, year= 2015, quarter= 1)
    project_anchor = ProjectAnchor.find(project_anchor_id)

    request = InvoicingRequest.new(year: year, quarter: quarter)
    contracted_entities = organisation_units(project_anchor, request)

    puts "contracted_entities #{contracted_entities.size}"

    contracted_entities.each_slice(50).each do |org_unit_ids|
      InvoicesForEntitiesWorker.new.perform(project_anchor_id, year, quarter, org_unit_ids)
    end
  end

  def organisation_units(project_anchor, request)
    request.quarter_dates.map do |quarter_date|
      pyramid = project_anchor.latest_pyramid_for(quarter_date)
      project = project_anchor.projects.for_date(quarter_date) || project_anchor.latest_draft
      contracted_entities = pyramid.org_units_in_all_groups([project.entity_group.external_reference])
      puts "quarter_date #{quarter_date.year}-#{quarter_date.month} => projects #{project.status} #{project.id} => #{contracted_entities.size}"
      contracted_entities.map(&:id)
    end.flatten.uniq.sort
  end
end
