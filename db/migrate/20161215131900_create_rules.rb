class CreateRules < ActiveRecord::Migration[5.0]
  def change
    create_table :rules do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.references :package, foreign_key: true
      t.timestamps
    end
  end
end
