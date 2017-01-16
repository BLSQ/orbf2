class RemoveProjectIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :project_id
  end
end
