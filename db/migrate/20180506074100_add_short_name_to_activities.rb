class AddShortNameToActivities < ActiveRecord::Migration[5.0]
  def change
    add_column :activities, :short_name, :string
  end
end
