class AddOauthClientSecretToPrograms < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :oauth_client_secret, :string, null: true
  end
end