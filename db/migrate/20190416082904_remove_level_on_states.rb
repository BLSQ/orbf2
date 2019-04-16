class RemoveLevelOnStates < ActiveRecord::Migration[5.2]
  def change
    remove_column :states, :level
  end
end
