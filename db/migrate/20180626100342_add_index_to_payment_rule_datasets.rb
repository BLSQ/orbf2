class AddIndexToPaymentRuleDatasets < ActiveRecord::Migration[5.0]
  def change
    add_index :payment_rule_datasets, %i[payment_rule_id frequency], unique: true
  end
end
