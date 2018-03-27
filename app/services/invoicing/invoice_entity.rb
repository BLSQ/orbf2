module Invoicing
  class InvoiceEntity
    def initialize(project_anchor, invoicing_request, options)
      @invoicing_request = invoicing_request
      @project_anchor = project_anchor
      @options = options || InvoicingOptions.default_options
    end

    def call
      fetch_and_solve
      publish_to_dhis2 if options.publish_to_dhis2?
    end

    attr_reader :invoicing_request, :project_anchor, :options

    def fetch_and_solve
      @fetch_and_solve ||= begin
          fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
            orbf_project,
            invoicing_request.entity,
            invoicing_request.year_quarter.to_dhis2,
            pyramid
          )
          @pyramid = fetch_and_solve.pyramid
          @dhis2_export_values = fetch_and_solve.call
          @dhis2_input_values = fetch_and_solve.dhis2_values
          fetch_and_solve
        end
    end

    def publish_to_dhis2
      Rails.logger.info "about to publish #{@dhis2_export_values.size} values to dhis2"
      return if @dhis2_export_values.empty?
      status = project.dhis2_connection.data_value_sets.create(@dhis2_export_values)
      Rails.logger.info @dhis2_export_values.to_json
      Rails.logger.info status.raw_status.to_json
      project.project_anchor.dhis2_logs.create(sent: @dhis2_export_values, status: status.raw_status)
    end

    def data_compound
      @datacompound ||= project.project_anchor
                               .nearest_data_compound_for(
                                 invoicing_request.end_date_as_date
                               )
      @datacompound ||= DataCompound.from(project) if options.allow_fresh_dhis2_data?

      @datacompound
    end

    def project
      @project ||= if options.force_project_id
                     project_anchor.projects.fully_loaded.find(options.force_project_id)
                   else
                     project_anchor.projects.fully_loaded.for_date(invoicing_request.end_date_as_date) ||
                       project_anchor.latest_draft
                   end
    end

    def orbf_project
      @orbf_project ||= MapProjectToOrbfProject.new(project, data_compound.indicators).map
    end

    def legacy_pyramid
      @legacy_pyramid ||= project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date) ||
                          project_anchor.nearest_pyramid_for(invoicing_request.start_date_as_date)
    end

    def pyramid
      @pyramid ||= if legacy_pyramid
                     Orbf::RulesEngine::PyramidFactory.from_dhis2(
                       org_units:          legacy_pyramid.org_units,
                       org_unit_groups:    legacy_pyramid.org_unit_groups,
                       org_unit_groupsets: legacy_pyramid.organisation_unit_group_sets
                     )
                   end
    end
  end
end
