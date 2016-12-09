class AddTimestampsToPackageStates < ActiveRecord::Migration[5.0]
  def change
    add_timestamps(:package_states)
  end
end
