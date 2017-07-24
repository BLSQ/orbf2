class ChangeIndexToActivities < ActiveRecord::Migration[5.0]
  def change
    remove_index :activities, :code
    add_index :activities, [:project_id,:code], unique: true
  end
end
