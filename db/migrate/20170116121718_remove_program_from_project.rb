class RemoveProgramFromProject < ActiveRecord::Migration[5.0]
  def change
    remove_column :projects, :program_id
  end
end
