class CreateProjectAnchor < ActiveRecord::Migration[5.0]
  def change
    create_table :project_anchors do |t|
      t.references :program, foreign_key: true, index: true, null: false
      t.timestamps
    end
  end
end
