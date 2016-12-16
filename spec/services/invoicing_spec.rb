require "rails_helper"

describe Invoicing::InvoiceBuilder do
  let(:analytics_service) { Analytics::MockAnalyticsService.new }
  let(:project_finder) { MockProjectFinder.new }
  let(:project) { ProjectFactory.new.build }

  it "should have a nice project" do
    json = project_finder.find_project(nil, Date.today).export_to_json
    obj = JSON.parse(json)
    puts JSON.pretty_unparse(obj)
    project.dump_rules
  end

  it "should generate quarterly and monthly invoices" do
    builder = Invoicing::InvoiceBuilder.new project_finder
    analytics_service.entities.each do |entity|
      [Date.today - 2.months, Date.today - 1.month, Date.today].each do |month|
        monthly_invoice = builder.generate_monthly_entity_invoice(project, entity, analytics_service, month)
        monthly_invoice.dump_invoice
      end
      quarterly_invoice = builder.generate_quarterly_entity_invoice(project, entity, analytics_service, Date.today)
    end
  end
end