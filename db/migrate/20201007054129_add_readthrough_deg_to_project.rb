# frozen_string_literal: true

class AddReadthroughDegToProject < ActiveRecord::Migration[5.2]
  def change
    # on existing project keep it false
    add_column :projects, :read_through_deg, :boolean, null: false, default: false
    # on newer project will default to true
    change_column :projects, :read_through_deg, :boolean, default: true
  end
end
