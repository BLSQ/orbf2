
module Invoicing
    class MapToInvoices
      def call(invoicing_request, fetch_and_solve)
        selected_periods = [
          invoicing_request.year_quarter.months.map(&:to_dhis2),
          invoicing_request.year_quarter.to_dhis2
        ].flatten.to_set

        invoicing_request.invoices = Orbf::RulesEngine::InvoicePrinter.new(
          fetch_and_solve.solver.variables,
          fetch_and_solve.solver.solution
        ).print

        invoicing_request.invoices = invoicing_request.invoices.select { |invoice|
          selected_periods.include?(invoice.period) && (invoice.activity_items.any? || invoice.total_items.any?)
        }.sort_by(&:period)
      end
    end
  end