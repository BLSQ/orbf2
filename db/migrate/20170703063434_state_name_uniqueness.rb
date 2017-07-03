class StateNameUniqueness < ActiveRecord::Migration[5.0]
  def change
    change_column :states, :project_id, :integer, null: false
    add_index :states, %i[project_id name], unique: true
  end
end
