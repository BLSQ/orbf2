class AddProjectQualifierToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :qualifier, :string, null: true
  end
end
