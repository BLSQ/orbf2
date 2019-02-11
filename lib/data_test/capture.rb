# frozen_string_literal: true

module DataTest
  class Capture
    include FileHelpers

    attr_accessor :subject

    def initialize(subject, output_directory = ARTEFACT_DIR)
      @subject = subject
      @output_directory = output_directory
    end

    def project_anchor_id
      @project_anchor_id ||= Project.find(subject.project_id).project_anchor_id
    end

    def project
      @project ||= Project.fully_loaded.find(subject.project_id)
    end

    def invoicing_period
      "#{subject.year}Q#{subject.quarter}"
    end

    def engine_version
      version = 3
      version = project.engine_version if project.engine_version > 1
      version
    end

    def call
      invoicing_request = InvoicingRequest.new(entity:         subject.orgunit_ext_id,
                                               year:           subject.year,
                                               quarter:        subject.quarter,
                                               engine_version: engine_version)
      options = Invoicing::InvoicingOptions.new(
        publish_to_dhis2: false,
        force_project_id: subject.project_id
      )
      invoice_entity = Invoicing::InvoiceEntity.new(project.project_anchor,
                                                    invoicing_request,
                                                    options)
      invoice_entity.call
      solver = invoice_entity.fetch_and_solve.solver

      password = project.password.dup
      capture_artefacts(invoice_entity, project)
      check_for_sensitive_data!(password)
      capture_results(solver, invoice_entity.fetch_and_solve.exported_values)
    end

    def capture_artefacts(invoice_entity, project)
      dump_data_compound(invoice_entity.data_compound)
      dump_pyramid(invoice_entity.pyramid)
      dump_input_values(invoice_entity.fetch_and_solve.dhis2_values)

      dump_project(project, invoice_entity.data_compound.indicators)
    end

    def dump_data_compound(compound)
      record_yaml(path_for_artefact("data-compound", "yml"), compound)
    end

    def dump_pyramid(pyramid)
      record_yaml(path_for_artefact("pyramid", "yml"), pyramid)
    end

    def dump_input_values(values)
      inputs = values.select do |value|
        value["storedBy"]
      end
      record_json(path_for_artefact("input-values", "json"), inputs)
    end

    def dump_project(project, indicators)
      project.dhis2_url = "https://redacted.example.com"
      project.user = "redacted"
      project.password = "redacted"
      data = MapProjectToOrbfProject.new(project, indicators, engine_version).map
      record_yaml(path_for_artefact("project", "yml"), data)
    end

    def check_for_sensitive_data!(password)
      result = `grep -F #{Shellwords.escape(password)} #{ARTEFACT_DIR}/*`
      abort "Passwords leaked! => \n#{result}" unless result.empty?
      result = `grep -F #{CGI.escape(password)} #{ARTEFACT_DIR}/*`
      abort "Passwords leaked! => \n#{result}" unless result.empty?
    end

    def capture_results(solver, exported_values)
      record_json(path_for_artefact("problem", "json"), solver.build_problem)
      record_json(path_for_artefact("solution", "json"), solver.solution)
      record_json(path_for_artefact("exported_values", "json"), exported_values)
    end

    def path_for_artefact(name, extension)
      parts = []
      parts << subject.name
      parts << name
      Pathname.new("#{@output_directory}/#{parts.join('-')}.#{extension}")
    end
  end
end
