class AddShortNameToFormulas < ActiveRecord::Migration[5.0]
  def change
    add_column :formulas, :short_name, :string
  end
end
