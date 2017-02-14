class AddFormulaToActivityStates < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_states, :formula, :string
    change_column_null(:activity_states, :external_reference, true)
  end
end
