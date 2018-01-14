module Invoicing
  class CreateForEntities
    include Support::Profiling

    OrgUnitAndPackages = Struct.new(:org_unit, :org_units_by_package)

    def initialize(project_anchor_id, year, quarter, org_unit_ids, options = {})
      @options        = default_options.merge(options)
      @project_anchor = ProjectAnchor.find(project_anchor_id)
      @org_unit_ids   = org_unit_ids
      @invoicing_request = InvoicingRequest.new(year: year, quarter: quarter)
      @project_finder = build_project_finder
    end

    def call
      profile("InvoicesForEntitiesWorker") do
        puts "************ invoices for #{project_anchor.id} - #{invoicing_request.year}/Q#{invoicing_request.quarter} -  #{org_unit_ids}"
        invoicing_request.project = project_finder.find_project(invoicing_request.end_date_as_date)

        create_invoices.tap do |invoices|
          publish(invoicing_request.project, invoices.values.flatten)
        end
      end
    end

    private

    attr_reader :project_anchor, :org_unit_ids, :options, :invoicing_request, :project_finder

    def create_invoices
      org_unit_and_packages.each_with_object({}) do |org_unit_and_package, hash|
        begin
          org_unit = org_unit_and_package.org_unit
          profile("calculate invoices #{org_unit.id}") do
            analytics_service = analytics_services_by_org_unit_id[org_unit.id]
            orgunit_invoices = calculate_invoices(
              org_unit,
              analytics_service
            )
            hash[org_unit.id] = orgunit_invoices
          end
        rescue Invoicing::InvoicingError => e
          puts e.message
        end
      end
    end

    def build_project_finder
      profile("load Project") do
        month_drafts = []
        months = invoicing_request.quarter_dates + [invoicing_request.year_quarter.to_year.end_date]
        if options[:force_project_id]
          draft = project_anchor.projects.fully_loaded.find(options[:force_project_id])
          month_drafts = months.each_with_object({}) { |date, h| h[date] = draft }
        else
          month_drafts = months.each_with_object({}) do |date, h|
            project = project_anchor.projects.fully_loaded.for_date(date) || project_anchor.latest_draft
            h[date] = project
          end
        end
        ConstantProjectFinder.new(month_drafts)
      end
    end

    def analytics_services_by_org_unit_id
      @analytics_services_by_org_unit_id ||= begin
        values = profile("fetch_values for #{org_unit_and_packages.size}") do
          fetch_values
        end

        # TODO: indicators might have changed over time
        indicators_expressions = profile("indicators_expressions") do
          fetch_indicators_expressions
        end

        values += Analytics::IndicatorCalculator.new.calculate(indicators_expressions, values)

        data_compound = invoicing_request.project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
        data_compound ||= DataCompound.from(invoicing_request.project) if options[:allow_fresh_dhis2_data]

        aggregation_per_data_elements = data_compound.data_elements.each_with_object({}) { |de, h| h[de.id] = de.aggregation_type }

        org_unit_and_packages.each_with_object({}) do |ou_and_packages, hash|
          hash[ou_and_packages.org_unit.id] = Analytics::CachedAnalyticsService.new(
            ou_and_packages.org_unit,
            ou_and_packages.org_units_by_package,
            values,
            aggregation_per_data_elements
          )
        end
      end
    end

    def publishers
      {
        "dummy" => Publishing::DummyInvoicePublisher.new,
        "dhis2" => Publishing::Dhis2InvoicePublisher.new
      }.slice(*publisher_ids).values
    end

    def publish(project, all_invoices)
      puts "generated #{all_invoices.size} invoices"

      publishers.each do |publisher|
        profile("publish #{all_invoices.size} invoices ") do
          publisher.publish(project, all_invoices)
        end
      end
    end

    def calculate_invoices(org_unit, analytics_service)
      invoice_builder = Invoicing::InvoiceBuilder.new(project_finder, Tarification::TarificationService.new)
      entity = Invoicing::EntityBuilder.new.to_entity(org_unit)
      [].tap do |invoices|
        invoicing_request.quarter_dates.each do |month|
          begin
            monthly_invoice = invoice_builder.generate_monthly_entity_invoice(
              entity,
              analytics_service,
              month
            )
            monthly_invoice.dump_invoice
            invoices << monthly_invoice
          rescue => e
            puts "WARN : generate_monthly_entity_invoice : #{e.message}"
          end
        end
        quarterly_invoices = invoice_builder.generate_quarterly_entity_invoice(
          entity,
          analytics_service,
          invoicing_request.end_date_as_date
        )
        invoices << quarterly_invoices

        yearly_invoices = invoice_builder.generate_yearly_entity_invoice(
          entity,
          analytics_service,
          invoicing_request.end_date_as_date
        )
        invoices << yearly_invoices

        payments_invoices = invoice_builder.generate_monthly_payments(
          invoicing_request.project,
          entity,
          invoices,
          invoicing_request
        )

        invoices << payments_invoices
      end.flatten
    end

    def org_unit_and_packages
      @org_unit_and_packages ||= begin
        profile("fetch_org_units") do
          pyramid = invoicing_request.project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
          pyramid ||= Pyramid.from(invoicing_request.project) if options[:allow_fresh_dhis2_data]
          org_unit_ids.map do |id|
            org_unit = pyramid.org_unit(id)
            org_units_by_package = org_units_by_package(invoicing_request.project, pyramid, org_unit)
            OrgUnitAndPackages.new(org_unit, org_units_by_package)
          end
        end
      end
    end

    def org_units_by_package(project, pyramid, org_unit)
      project.packages.each_with_object({}) do |package, hash|
        hash[package] = package.linked_org_units(org_unit, pyramid)
      end
    end

    def fetch_indicators_expressions
      indicator_ids = invoicing_request.project.activities
                                       .flat_map(&:activity_states)
                                       .select(&:kind_indicator?)
                                       .map(&:external_reference)
      return {} if indicator_ids.empty?
      data_compound = invoicing_request.project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
      data_compound ||= DataCompound.from(invoicing_request.project) if options[:allow_fresh_dhis2_data]
      indicators = data_compound.indicators(indicator_ids)
      indicators.each_with_object({}) { |indicator, h| h[indicator.id] = Analytics::IndicatorCalculator.parse_expression(indicator.numerator) }
    end

    def fetch_values
      if options[:mock_values] == true
        puts "using mock values !"
        return org_unit_and_packages.map { |ou| mock_values(ou.org_units_by_package) }.flatten
      end
      dhis2 = invoicing_request.project.dhis2_connection
      packages = invoicing_request.project.packages
      dataset_ids = packages.flat_map(&:package_states).map(&:ds_external_reference).reject(&:nil?)
      org_units = org_unit_and_packages
                  .flat_map(&:org_units_by_package)
                  .flat_map(&:values)
                  .flatten

      org_unit_ids = org_units.map { |ou| ou.path.split("/").reject(&:empty?) }.flatten.uniq

      data_range = invoicing_request.project.date_range(invoicing_request.year_quarter)

      values_query = {
        organisation_unit: org_unit_ids,
        data_sets:         dataset_ids,
        start_date:        data_range.first,
        end_date:          data_range.last,
        children:          false
      }
      puts "fetching values #{values_query.to_json}"
      values = dhis2.data_value_sets.list(values_query)
      values.data_values ? values.values : []
    end

    def mock_values(_org_units_by_package)
      [].tap do |values|
        _org_units_by_package.each do |package, org_units|
          periods = invoicing_request.year_quarter.months.map(&:to_dhis2)
          periods += [invoicing_request.year_quarter.to_year.to_dhis2] if package.frequency == "yearly"
          periods.each do |period|
            package.activities.each do |activity|
              package.states.each do |state|
                org_units.each do |org_unit_to_mock|
                  activity_state = activity.activity_state(state)
                  next unless activity_state
                  value = if state.code == "tarif"
                            11
                          else
                            rand(6...11)
                          end
                  values.push OpenStruct.new(
                    data_element: activity_state.external_reference,
                    period:       period,
                    org_unit:     org_unit_to_mock.id,
                    value:        value
                  )
                end
              end
            end
          end
        end
      end
    end

    def default_options
      {
        publisher_ids:          %w[dummy dhis2],
        mock_values:            false,
        force_project_id:       nil,
        allow_fresh_dhis2_data: false
      }
    end

    def publisher_ids
      default_options[:publisher_ids]
    end
  end
end
