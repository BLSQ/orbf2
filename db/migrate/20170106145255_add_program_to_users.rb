class AddProgramToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :program, index: true
    add_foreign_key :users, :programs
  end
end
