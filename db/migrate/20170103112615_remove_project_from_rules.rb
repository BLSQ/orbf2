class RemoveProjectFromRules < ActiveRecord::Migration[5.0]
  def change
    remove_column :rules, :project_id
  end
end
