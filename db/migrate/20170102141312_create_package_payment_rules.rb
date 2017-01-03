class CreatePackagePaymentRules < ActiveRecord::Migration[5.0]
  def change
    create_table :package_payment_rules do |t|
      t.references :package, foreign_key: true, null: false
      t.references :payment_rule, foreign_key: true, null: false
      t.timestamps
    end
  end
end
