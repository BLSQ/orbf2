class AddTimestampsToEntityGroups < ActiveRecord::Migration[5.0]
  def change
    add_timestamps(:entity_groups)
  end
end
