class AddCalendarNameToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :calendar_name, :string, default: "gregorian", null: false
  end
end
