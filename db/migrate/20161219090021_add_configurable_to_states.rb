class AddConfigurableToStates < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :configurable, :boolean, default: false, null: false
  end
end
