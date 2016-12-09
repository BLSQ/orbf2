class AddTimestampsToPackageEntityGroups < ActiveRecord::Migration[5.0]
  def change
    add_timestamps(:package_entity_groups)
  end
end
