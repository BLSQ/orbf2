class CreatePaymentRuleDatasets < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_rule_datasets do |t|
      t.references :payment_rule, foreign_key: true
      t.string :frequency
      t.string :external_reference
      t.datetime :last_synched_at
      t.string :last_error
      t.boolean :desynchronized

      t.timestamps
    end
  end
end
