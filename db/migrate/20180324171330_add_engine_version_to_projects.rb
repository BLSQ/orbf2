class AddEngineVersionToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :engine_version, :integer, null: false, default: 1
  end
end
