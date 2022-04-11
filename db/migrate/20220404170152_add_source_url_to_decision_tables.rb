class AddSourceUrlToDecisionTables < ActiveRecord::Migration[5.2]
  def change
    add_column :decision_tables, :source_url, :string, null: true
  end
end