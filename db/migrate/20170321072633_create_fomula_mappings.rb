class CreateFomulaMappings < ActiveRecord::Migration[5.0]
  def change
    create_table :formula_mappings do |t|
      t.references :formula, foreign_key: true, null: false
      t.references :activity, foreign_key: true
      t.string :external_reference, null: false
      t.string :kind, null: false
    end
  end
end
