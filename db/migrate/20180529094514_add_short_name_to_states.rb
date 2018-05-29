class AddShortNameToStates < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :short_name, :string, null: true
  end
end
