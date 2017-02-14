class CreateActivity < ActiveRecord::Migration[5.0]
  def change
    create_table :activities do |t|
      t.string :name, null: false
      t.references :project, foreign_key: true, null: false
      t.uuid :stable_id, default: "uuid_generate_v4()", null: false
      t.timestamps
    end
    add_index :activities, [:name, :project_id], unique: true
  end
end
