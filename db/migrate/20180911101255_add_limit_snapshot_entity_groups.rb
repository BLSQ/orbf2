# frozen_string_literal: true

class AddLimitSnapshotEntityGroups < ActiveRecord::Migration[5.0]
  def change
    add_column :entity_groups, :limit_snaphot_to_active_regions, :boolean, default: false, null: false
  end
end
