class AddUuidToRules < ActiveRecord::Migration[5.0]
  def change
    add_column :rules, :stable_id, :uuid, default: "uuid_generate_v4()", null: false
  end
end
