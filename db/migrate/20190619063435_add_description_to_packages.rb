class AddDescriptionToPackages < ActiveRecord::Migration[5.2]
  def change
    add_column :packages, :description, :string
  end
end
