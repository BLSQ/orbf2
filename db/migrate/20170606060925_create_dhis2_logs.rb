class CreateDhis2Logs < ActiveRecord::Migration[5.0]
  def change
    create_table :dhis2_logs do |t|
      t.jsonb :sent
      t.jsonb :status
      t.references :project_anchor, foreign_key: true
      t.timestamps
    end
  end
end
