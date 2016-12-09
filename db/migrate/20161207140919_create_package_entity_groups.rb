class CreatePackageEntityGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :package_entity_groups do |t|
      t.string :name
      t.references :package, foreign_key: true
      t.string :organisation_unit_group_ext_ref
    end
  end
end
