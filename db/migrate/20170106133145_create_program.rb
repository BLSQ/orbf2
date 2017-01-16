class CreateProgram < ActiveRecord::Migration[5.0]
  def change
    create_table :programs do |t|
      t.string :code, null: false
      t.timestamps
    end
    add_index :programs, :code, unique: true
  end
end
