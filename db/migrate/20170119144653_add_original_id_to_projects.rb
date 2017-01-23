class AddOriginalIdToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :original_id, :integer, null: true, index: true
    add_foreign_key :projects, :projects, column: :original_id
  end
end
