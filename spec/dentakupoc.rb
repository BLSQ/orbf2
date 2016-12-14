require "rails_helper"
require "dentaku"
require "dentaku/calculator"

puts "************************************ activity value to amount"

def new_formula(code, expression, label)
  Formula.new(code: code, expression: expression, label: label)
end

def new_package(name, frequency, groups, rules, invoice_details)
  p = Package.new(name: name, frequency: frequency)
  p.package_entity_groups = groups.map { |g| PackageEntityGroup.new(name: g, organisation_unit_group_ext_ref: g) }
  p.rules = rules
  p.invoice_details = invoice_details
  p
end

analytics_service = Analytics::MockAnalyticsService.new
project_finder = MockProjectFinder.new
builder = Invoicing::InvoiceBuilder.new project_finder
project = ProjectFactory.new.build
analytics_service.entities.each do |entity|
  puts "*****************"
  puts "** Monthly ****** #{entity}"
  puts "*****************"
  monthly_invoice = builder.generate_monthly_entity_invoice(project, entity, analytics_service, Date.today - 2.months)
  monthly_invoice.dump_invoice

  monthly_invoice = builder.generate_monthly_entity_invoice(project, entity, analytics_service, Date.today - 1.month)
  monthly_invoice.dump_invoice

  monthly_invoice = builder.generate_monthly_entity_invoice(project, entity, analytics_service, Date.today)
  monthly_invoice.dump_invoice

  puts "*****************"
  puts "** Quaterly ****"
  puts "*****************"
  quaterly_invoice = builder.generate_quaterly_entity_invoice(project, entity, analytics_service, Date.today)
end

json = project_finder.find_project(nil, Date.today).to_json(
  except:  [:created_at, :updated_at, :password, :user],
  include: {
    packages: {
      methods: [:rules],
      except:  [:created_at, :updated_at]
    }
  },
  methods: [:payment_rule]

)
obj = JSON.parse(json)
puts JSON.pretty_unparse(obj)

puts
