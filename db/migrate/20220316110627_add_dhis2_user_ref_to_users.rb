class AddDhis2UserRefToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :dhis2_user_ref, :string, null: true
  end
end