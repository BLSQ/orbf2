class AddOauthClientIdToPrograms < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :oauth_client_id, :string, null: true
  end
end