class AddExternalReferenceToPackageStates < ActiveRecord::Migration[5.0]
  def change
    add_column :package_states, :de_external_reference, :string
  end
end
