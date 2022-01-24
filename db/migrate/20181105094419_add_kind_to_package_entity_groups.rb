class AddKindToPackageEntityGroups < ActiveRecord::Migration[5.0]
  def change
    add_column :package_entity_groups, :kind, :string, default: "main", null: false
  end
end
