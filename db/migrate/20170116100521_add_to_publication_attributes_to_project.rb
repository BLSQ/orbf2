class AddToPublicationAttributesToProject < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :status, :string, default: "draft", null: false
    add_column :projects, :publish_date, :datetime, null: true
    add_reference :projects, :project_anchor, index: true
    add_foreign_key :projects, :project_anchors
  end
end
