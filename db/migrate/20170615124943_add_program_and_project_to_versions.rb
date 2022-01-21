class AddProgramAndProjectToVersions < ActiveRecord::Migration[5.0]
  def change
    add_reference :versions, :program, index: true, foreign_key: true
    add_reference :versions, :project, index: true, foreign_key: true
  end
end
