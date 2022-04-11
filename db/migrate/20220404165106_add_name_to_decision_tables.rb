class AddNameToDecisionTables < ActiveRecord::Migration[5.2]
  def change
    add_column :decision_tables, :name, :string, null: true
  end
end