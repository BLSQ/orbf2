class AddProjectToStates < ActiveRecord::Migration[5.0]
  def change
    add_reference :states, :project, foreign_key: true
    remove_index :states, :name
  end
end
