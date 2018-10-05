class AddGroupSetsExtIdsToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :groupsets_ext_refs, :string, array: true, default: []
  end
end
