require "rails_helper"

describe Invoicing::InvoiceBuilder do
  let(:analytics_service) { Analytics::MockAnalyticsService.new }
  let(:project_finder) { MockProjectFinder.new }
  let(:project) { ProjectFactory.new.build }
  let(:entities) {[
    Analytics::Entity.new(1, "Maqokho HC", ["hospital_group_id"]),
    Analytics::Entity.new(2, "fosa", ["fosa_group_id"])
  ]}


  it "should have a nice project" do
    json = project_finder.find_project(Date.today).export_to_json
    obj = JSON.parse(json)
    Rails.logger.info JSON.pretty_unparse(obj)
    project.dump_rules
  end

  it "should generate quarterly and monthly invoices" do
    builder = Invoicing::InvoiceBuilder.new project_finder
    entities.each do |entity|
      [(Date.today - 2.months).end_of_month, (Date.today - 1.month).end_of_month, (Date.today).end_of_month].each do |month|
        monthly_invoice = builder.generate_monthly_entity_invoice(entity, analytics_service, month)
        monthly_invoice.dump_invoice
      end
      quarterly_invoice = builder.generate_quarterly_entity_invoice(entity, analytics_service, Date.today.end_of_month)
    end
  end
end
