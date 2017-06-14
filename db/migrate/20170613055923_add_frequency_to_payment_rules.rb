class AddFrequencyToPaymentRules < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_rules, :frequency, :string, null: false,  default: "quarterly"
  end
end
