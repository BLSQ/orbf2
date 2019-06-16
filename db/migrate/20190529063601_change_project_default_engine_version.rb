class ChangeProjectDefaultEngineVersion < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:projects, :engine_version, from: 1, to: 3)
  end
end
