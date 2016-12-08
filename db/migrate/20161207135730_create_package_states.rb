class CreatePackageStates < ActiveRecord::Migration[5.0]
  def change
    create_table :package_states do |t|
      t.references :package, foreign_key: true
      t.references :state, foreign_key: true
      t.index [:package_id, :state_id], unique: true
      t.index [:state_id, :package_id], unique: true
    end
  end
end
