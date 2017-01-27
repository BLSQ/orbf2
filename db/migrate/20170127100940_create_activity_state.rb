class CreateActivityState < ActiveRecord::Migration[5.0]
  def change
    create_table :activity_states do |t|
      t.string :external_reference, null: false
      t.string :name, null: false
      t.references :state, foreign_key: true, null: false
      t.references :activity, foreign_key: true, null: false
      t.uuid :stable_id, default: "uuid_generate_v4()", null: false
      t.timestamps
    end
    add_index :activity_states, [:external_reference, :activity_id], unique: true
  end
end
