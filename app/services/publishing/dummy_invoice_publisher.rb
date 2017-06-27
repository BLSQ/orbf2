module Publishing
  class DummyInvoicePublisher
    def publish(_project, invoices)
      invoices.each do |invoice|
        invoice.dump_invoice(true)
        puts invoice.lines.join("\n")
      end
    end
  end
end
