# frozen_string_literal: true

require "fileutils"

module DataTest
  class Verifier
    include FileHelpers

    attr_accessor :subject

    def initialize(subject)
      @subject = subject
      ensure_directory_exists
    end

    def read_artefact(name, extension)
      parts = []
      parts << subject.name
      parts << name
      path = Pathname.new("#{ARTEFACT_DIR}/#{parts.join('-')}.#{extension}")
      if extension == "json"
        read_json(path)
      else
        read_yaml(path)
      end
    end

    def call
      DataCompound
      invoicing_request = InvoicingRequest.new(
        entity:      subject.orgunit_ext_id,
        year:        subject.year,
        quarter:     subject.quarter,
        mocked_data: read_artefact("input-values", "json")
      )
      options = Invoicing::InvoicingOptions.new(
        publish_to_dhis2: false,
        force_project_id: subject.project_id
      )
      invoice_entity = Invoicing::InvoiceEntity.new(nil, invoicing_request, options)
      invoice_entity.instance_variable_set(:@pyramid, read_artefact("pyramid", "yml"))
      invoice_entity.instance_variable_set(:@datacompound, read_artefact("data-compound", "yml"))
      invoice_entity.instance_variable_set(:@orbf_project, read_orbf_project())
      invoice_entity.call
      solver = invoice_entity.fetch_and_solve.solver
      capture_results(solver, invoice_entity.fetch_and_solve.exported_values)
    end

    def read_orbf_project
      orbf_project = read_artefact("project", "yml")
      orbf_project.packages.each { |p| p.project = orbf_project }
      orbf_project.payment_rules.each { |p| p.project = orbf_project }
      orbf_project
    end

    def ensure_directory_exists
      FileUtils.mkdir_p RESULTS_DIR unless File.exist? RESULTS_DIR
    end

    def path_for_result(name, extension)
      parts = []
      parts << subject.name
      parts << name
      Pathname.new("#{RESULTS_DIR}/#{parts.join('-')}.#{extension}")
    end

    def capture_results(solver, exported_values)
      record_json(path_for_result("problem", "json"), solver.build_problem)
      record_json(path_for_result("solution", "json"), solver.solution)
      record_json(path_for_result("exported_values", "json"), exported_values)
    end
  end
end
