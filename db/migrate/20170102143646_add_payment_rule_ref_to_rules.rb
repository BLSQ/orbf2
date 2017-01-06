class AddPaymentRuleRefToRules < ActiveRecord::Migration[5.0]
  def change
    add_reference :rules, :payment_rule, foreign_key: true
  end
end
