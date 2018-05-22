class AddCocAndAocToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :default_coc_reference, :string
    add_column :projects, :default_aoc_reference, :string
  end
end
