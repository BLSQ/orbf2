# frozen_string_literal: true

module Invoicing
  class InvoiceEntity
    def initialize(project_anchor, invoicing_request, options)
      @invoicing_request = invoicing_request
      @project_anchor = project_anchor
      @options = options || InvoicingOptions.default_options
    end

    def profile_id
      invoicing_request&.entity
    end

    def call
      if ignore_non_contracted?
        Rails.logger.warn("#{invoicing_request.entity} is not contracted. Stopping invoicing")
        return
      end

      fetch_and_solve
      publish_to_dhis2 if options.publish_to_dhis2?
      @success = true
    end

    def success?
      @success
    end

    attr_reader :invoicing_request, :project_anchor, :options

    def ignore_non_contracted?
      return false unless options.ignore_non_contracted?

      return false if project.entity_group.contract_program_based?

      # let it fail later if orgunit not found
      # else check the contracted entity group
      legacy_org_unit = pyramid.org_unit(invoicing_request.entity)
      return false unless legacy_org_unit

      contracted = pyramid.belong_to_group(
        legacy_org_unit,
        project.entity_group.external_reference
      )
      !contracted
    end

    def fetch_and_solve
      @fetch_and_solve ||= begin
          solve_options = {
            pyramid:     pyramid,
            mock_values: invoicing_request.mocked_data
          }

          @fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
            orbf_project,
            invoicing_request.entity,
            invoicing_request.invoicing_period,
            solve_options
          )
          @pyramid = @fetch_and_solve.pyramid
          @dhis2_export_values = @fetch_and_solve.call
          @dhis2_input_values = @fetch_and_solve.dhis2_values
          @fetch_and_solve
        end
    end

    def publish_to_dhis2
      Rails.logger.info "about to publish #{@dhis2_export_values.size} values to dhis2"
      return if @dhis2_export_values.empty?

      status = if Flipper[:use_parallel_publishing].enabled?(project.project_anchor)
                 parallel_publish_to_dhis2
               else
                 project.dhis2_connection.data_value_sets.create(@dhis2_export_values)
               end

      # minimize memory usage, don't log exported values but only the status
      # Rails.logger.info @dhis2_export_values.to_json
      Rails.logger.info status.raw_status.to_json

      if project.dhis2_logs_enabled
        project.project_anchor.dhis2_logs.create(
          sent:             @dhis2_export_values,
          status:           status.raw_status,
          invoicing_job_id: options.invoicing_job_id,
          sidekiq_job_ref:  options.sidekiq_job_ref
        )
      end
      ConflictsHandler.new(status).raise_if_blocking_conflicts?
    end

    def parallel_publish_to_dhis2
      url = project.dhis2_connection.instance_variable_get(:@base_url)
      client = ParallelDhis2.new(project.dhis2_connection)
      client.post_data_value_sets(@dhis2_export_values)
    end

    def data_compound
      @datacompound ||= project.project_anchor
                               .nearest_data_compound_for(
                                 invoicing_request&.end_date_as_date
                               )
      @datacompound ||= DataCompound.from(project) if options.allow_fresh_dhis2_data?

      @datacompound
    end

    def project
      @project ||= if options.force_project_id
                     project_anchor.projects.fully_loaded.find(options.force_project_id)
                   else
                     project_anchor.projects.fully_loaded.for_date(invoicing_request&.end_date_as_date) ||
                       project_anchor.latest_draft
                   end
    end

    def orbf_project
      @orbf_project ||= MapProjectToOrbfProject.new(
        project,
        data_compound.indicators,
        data_compound.category_combos,
        data_compound.data_elements,
        invoicing_request.engine_version
      ).map
    end

    def snapshot
      @snapshot ||= project_anchor.nearest_pyramid_snapshot_for(invoicing_request.end_date_as_date) ||
                    project_anchor.nearest_pyramid_snapshot_for(invoicing_request.start_date_as_date)
    end

    def pyramid
      @pyramid ||= if snapshot
                     Orbf::RulesEngine::PyramidFactory.from_snapshot(
                       org_units:          snapshot[:organisation_units].content,
                       org_unit_groups:    snapshot[:organisation_unit_groups].content,
                       org_unit_groupsets: snapshot[:organisation_unit_group_sets].content
                     )
                   end
    end
  end
end
