class AddDhis2LogsEnabledToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :dhis2_logs_enabled, :boolean, default: true, null: false
    add_column :projects, :enabled, :boolean, default: true, null: false
  end
end
