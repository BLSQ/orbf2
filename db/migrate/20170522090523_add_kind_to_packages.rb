class AddKindToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :kind, :string, default: "single"
    add_column :packages, :ogs_reference, :string
  end
end
