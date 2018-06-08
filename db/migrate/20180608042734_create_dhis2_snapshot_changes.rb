class CreateDhis2SnapshotChanges < ActiveRecord::Migration[5.0]
  def change
    create_table :dhis2_snapshot_changes do |t|
      t.string :dhis2_id, null:false
      t.references :dhis2_snapshot, foreign_key: true
      t.jsonb :values_before
      t.jsonb :values_after
      t.string :whodunnit

      t.timestamps
    end
  end
end
