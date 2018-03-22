class AddDhis2VersionToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :dhis2_version, :string, null: false, default: "2.24"
  end
end
