class AddKindToActivityStates < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_states, :kind, :string, null: false, default: "data_element"
  end
end
