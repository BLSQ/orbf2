class AddProjectToRules < ActiveRecord::Migration[5.0]
  def change
    add_reference :rules, :project, foreign_key: true
  end
end
