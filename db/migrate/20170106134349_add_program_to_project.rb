class AddProgramToProject < ActiveRecord::Migration[5.0]
  def change
    add_reference :projects, :program, index: true, null: false
    add_foreign_key :projects, :programs
  end
end
