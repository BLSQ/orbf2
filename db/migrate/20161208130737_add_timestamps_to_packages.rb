class AddTimestampsToPackages < ActiveRecord::Migration[5.0]
  def change
    add_timestamps(:packages)
  end
end
