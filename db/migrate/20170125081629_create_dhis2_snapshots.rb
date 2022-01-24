class CreateDhis2Snapshots < ActiveRecord::Migration[5.0]
  def change
    create_table :dhis2_snapshots do |t|
      t.string :kind, null: false
      t.jsonb :content, null: false
      t.references :project_anchor, foreign_key: true
      t.string :dhis2_version, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.string :job_id, null: false

      t.timestamps
    end
  end
end
