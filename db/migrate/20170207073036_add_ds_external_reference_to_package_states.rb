class AddDsExternalReferenceToPackageStates < ActiveRecord::Migration[5.0]
  def change
    add_column :package_states, :ds_external_reference, :string
    add_column :package_states, :deg_external_reference, :string
  end
end
