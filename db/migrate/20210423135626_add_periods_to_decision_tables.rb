class AddPeriodsToDecisionTables < ActiveRecord::Migration[5.2]
  def change
    add_column :decision_tables, :start_period, :string, null: true
    add_column :decision_tables, :end_period, :string, null: true
  end
end
