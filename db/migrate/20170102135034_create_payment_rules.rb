class CreatePaymentRules < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_rules do |t|
      t.references :project, foreign_key: true, null: false
      t.timestamps
    end
  end
end
