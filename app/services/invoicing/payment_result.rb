module Invoicing
  class PaymentResult < Struct.new(:payment_rule, :solution, :variables)
    def to_s
      "#{payment_rule.name}  #{solution}"
    end

    delegate :to_json, to: :to_h
  end
end
