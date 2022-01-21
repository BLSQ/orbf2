class ChangeObjectTypeColumnInVersions < ActiveRecord::Migration[5.0]
  def change
    rename_column :versions, :object, :old_object
    add_column :versions, :object, :jsonb # or :json
  end
end
