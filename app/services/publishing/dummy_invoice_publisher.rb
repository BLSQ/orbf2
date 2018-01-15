module Publishing
  class DummyInvoicePublisher
    def publish(_project, invoices)
      invoices.each do |invoice|
        invoice.dump_invoice(true)
        Rails.logger.info invoice.lines.join("\n")
      end
    end
  end
end
