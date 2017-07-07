class AddCycleToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :cycle, :string, null: false, default: "quarterly"
  end
end
