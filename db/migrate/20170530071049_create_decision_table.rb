class CreateDecisionTable < ActiveRecord::Migration[5.0]
  def change
    create_table :decision_tables do |t|
      t.references :rule, foreign_key: true
      t.text :content
    end
  end
end
