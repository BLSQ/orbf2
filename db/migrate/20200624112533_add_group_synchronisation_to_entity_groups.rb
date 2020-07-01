class AddGroupSynchronisationToEntityGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :entity_groups, :group_synchronisation_enabled, :boolean, default: false, null: false
    add_column :entity_groups, :contract_delay_in_months, :integer, default: 1, null: true
  end
end
