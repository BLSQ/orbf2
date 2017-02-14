class CreateActivityPackage < ActiveRecord::Migration[5.0]
  def change
    create_table :activity_packages do |t|
      t.references :activity, foreign_key: true, null: false
      t.references :package, foreign_key: true, null: false
      t.uuid :stable_id, default: "uuid_generate_v4()", null: false
      t.timestamps
    end
    add_index :activity_packages, [:package_id, :activity_id], unique: true
  end
end
