module Invoicing
  class PaymentResult < Struct.new(:payment_rule, :solution)
    def to_s
      "#{payment_rule.name}  #{solution}"
    end
    def to_json(options)
      to_h.to_json(options)
    end
  end
end
