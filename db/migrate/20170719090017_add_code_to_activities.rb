class AddCodeToActivities < ActiveRecord::Migration[5.0]
  def change
    add_column :activities, :code, :string, null: true
    add_index :activities, :code, unique: true
  end
end
