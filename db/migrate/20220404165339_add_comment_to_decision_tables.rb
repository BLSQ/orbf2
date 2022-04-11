class AddCommentToDecisionTables < ActiveRecord::Migration[5.2]
  def change
    add_column :decision_tables, :comment, :text, null: true
  end
end