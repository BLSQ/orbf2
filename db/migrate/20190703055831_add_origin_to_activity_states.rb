# frozen_string_literal: true

class AddOriginToActivityStates < ActiveRecord::Migration[5.2]
  def change
    add_column :activity_states, :origin, :string, default: "dataValueSets"
  end
end
