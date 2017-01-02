class AddLevelToStates < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :level, :string, default: "activity", null: false
  end
end
