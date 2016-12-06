class CreatePackages < ActiveRecord::Migration[5.0]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.string :data_element_group_ext_ref, null: false
      t.string :frequency, null: false
      t.references :project, foreign_key: true, index: true
    end
  end
end
