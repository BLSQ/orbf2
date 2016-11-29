class AddProjectRefToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :project, foreign_key: true, index: true
  end
end
