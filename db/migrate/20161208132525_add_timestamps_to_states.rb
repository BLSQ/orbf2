class AddTimestampsToStates < ActiveRecord::Migration[5.0]
  def change
    add_timestamps(:states)
  end
end
