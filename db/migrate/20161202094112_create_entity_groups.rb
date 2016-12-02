class CreateEntityGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :entity_groups do |t|
      t.string :name
      t.string :external_reference
      t.references :project, foreign_key: true
    end
  end
end
