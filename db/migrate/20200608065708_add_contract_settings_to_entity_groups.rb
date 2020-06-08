class AddContractSettingsToEntityGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :entity_groups, :kind, :string,  default: "group_based"
    add_column :entity_groups, :program_reference, :string
    add_column :entity_groups, :all_event_sql_view_reference, :string
  end
end
