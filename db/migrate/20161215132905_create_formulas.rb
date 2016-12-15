class CreateFormulas < ActiveRecord::Migration[5.0]
  def change
    create_table :formulas do |t|
      t.string :code, null: false
      t.string :description, null: false
      t.text :expression, null: false
      t.references :rules, foreign_key: true
      t.timestamps
    end
  end
end
