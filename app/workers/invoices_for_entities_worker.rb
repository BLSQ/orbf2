
class InvoicesForEntitiesWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, year, quarter, org_unit_ids)
    profile("InvoicesForEntitiesWorker") do
      do_perform(project_anchor_id, year, quarter, org_unit_ids)
    end
  end


  def do_perform(project_anchor_id, year, quarter, org_unit_ids)
  project_anchor = ProjectAnchor.find(project_anchor_id)

  puts "************ invoices for #{project_anchor_id} - #{year}/Q#{quarter} -  #{org_unit_ids}"
  invoicing_request = InvoicingRequest.new(year: year, quarter: quarter)
  project = profile("load Project") do
     project_anchor.projects.fully_loaded.for_date(invoicing_request.end_date_as_date) || project_anchor.latest_draft
  end
  invoicing_request.project = project
  org_units_by_id =  profile("fetch_org_units") do
    fetch_org_units(project, org_unit_ids).index_by(&:id)
  end

  values = profile("fetch_values for #{org_unit_ids.size}") do
    fetch_values(invoicing_request, org_unit_ids)
  end
  indicators_expressions = profile("indicators_expressions") do
    fetch_indicators_expressions(project)
  end

  org_unit_ids.each do |org_unit_id|
    org_unit = org_units_by_id[org_unit_id]
    profile("calculate invoices #{org_unit_id}") do
      calculate_invoices(invoicing_request, org_unit, values, indicators_expressions)
    end
  end
end

  def profile(message, &block)
    start = Time.now.utc
    element = yield block
    elapsed = Time.now.utc - start
    puts "\t => #{message} in #{elapsed}\t|\t#{MemInfo.rss}"
    element
  end

  module MemInfo
    # This uses backticks to figure out the pagesize, but only once
    # when loading this module.
    # You might want to move this into some kind of initializer
    # that is loaded when your app starts and not when autoload
    # loads this module.
    KERNEL_PAGE_SIZE = `getconf PAGESIZE`.chomp.to_i rescue 4096
    STATM_PATH       = "/proc/#{Process.pid}/statm"
    STATM_FOUND      = File.exist?(STATM_PATH)

    def self.rss
      STATM_FOUND ? (File.read(STATM_PATH).split(' ')[1].to_i * KERNEL_PAGE_SIZE) / 1024 : 0
    end
  end

  def calculate_invoices(invoicing_request, org_unit, values, indicators_expressions)
    values += Analytics::IndicatorCalculator.new.calculate(indicators_expressions, values)

    entity = Analytics::Entity.new(org_unit.id, org_unit.name, org_unit.organisation_unit_groups.map { |n| n["id"] })
    # TODO: don't use constant project finder but based on date
    invoice_builder = Invoicing::InvoiceBuilder.new(ConstantProjectFinder.new(invoicing_request.project), Tarification::TarificationService.new)
    analytics_service = Analytics::CachedAnalyticsService.new([org_unit], values)

    invoices = []
    invoicing_request.quarter_dates.each do |month|
      monthly_invoice = invoice_builder.generate_monthly_entity_invoice(invoicing_request.project, entity, analytics_service, month)
      monthly_invoice.dump_invoice
      invoices << monthly_invoice
    end
    quarterly_invoices = invoice_builder.generate_quarterly_entity_invoice(invoicing_request.project, entity, analytics_service, invoicing_request.end_date_as_date)
    invoices << quarterly_invoices
    invoices.flatten
  end

  def fetch_org_units(project, ids)
    # TODO: use dhis2 snapshot
    project.dhis2_connection.organisation_units.find(ids)
  end

  def fetch_indicators_expressions(project)
    # TODO: use dhis2 snapshot
    indicator_ids = project.activities.flat_map(&:activity_states).select(&:kind_indicator?).map(&:external_reference)
    return {} if indicator_ids.empty?
    indicators = project.dhis2_connection.indicators.find(indicator_ids)
    Hash[indicators.map { |indicator| [indicator.id, Analytics::IndicatorCalculator.parse_expression(indicator.numerator)] }]
  end

  def fetch_values(invoicing_request, org_unit_ids)
    dhis2 = invoicing_request.project.dhis2_connection
    packages = invoicing_request.project.packages
    dataset_ids = packages.flat_map(&:package_states).map(&:ds_external_reference).reject(&:nil?)

    values_query = {
      organisation_unit: org_unit_ids,
      data_sets:         dataset_ids,
      start_date:        invoicing_request.start_date_as_date,
      end_date:          invoicing_request.end_date_as_date,
      children:          false
    }
    values = dhis2.data_value_sets.list(values_query)
    values.data_values ? values.values : []
  end
end
