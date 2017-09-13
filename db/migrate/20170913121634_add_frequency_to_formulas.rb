class AddFrequencyToFormulas < ActiveRecord::Migration[5.0]
  def change
    add_column :formulas, :frequency, :string
  end
end
