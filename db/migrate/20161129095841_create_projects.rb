class CreateProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :dhis2_url, null: false
      t.string :user
      t.string :password
      t.boolean :bypass_ssl, :boolean, default: false

      t.timestamps
    end
  end
end
