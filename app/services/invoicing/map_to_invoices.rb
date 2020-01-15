
module Invoicing
  class MapToInvoices
    def initialize(invoicing_request, solver)
      @invoicing_request = invoicing_request
      @solver = solver
    end

    def call
      invoices = print_invoices.select do |invoice|
        selected_periods.include?(invoice.period) && non_empty?(invoice)
      end
      invoicing_request.invoices = invoices.sort_by(&:period)
    end

    private

    attr_reader :invoicing_request, :solver

    def print_invoices
      Orbf::RulesEngine::InvoicePrinter.new(
        solver.variables,
        solver.solution
      ).print
    end

    def non_empty?(invoice)
      invoice.activity_items.any? || invoice.total_items.any?
    end

    def selected_periods
      @selected_periods ||= [
        invoicing_request.project.calendar.periods(invoicing_request.year_quarter.to_dhis2, "monthly"),
        invoicing_request.year_quarter.to_dhis2
      ].flatten.to_set
    end
  end
end
