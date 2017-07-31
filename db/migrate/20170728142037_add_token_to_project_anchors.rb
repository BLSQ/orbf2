class AddTokenToProjectAnchors < ActiveRecord::Migration[5.0]
  def change
    add_column :project_anchors, :token, :string
  end
end
