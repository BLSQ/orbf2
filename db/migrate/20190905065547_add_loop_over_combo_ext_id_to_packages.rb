class AddLoopOverComboExtIdToPackages < ActiveRecord::Migration[5.2]
  def change
    add_column :packages, :loop_over_combo_ext_id, :string
  end
end
