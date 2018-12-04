# frozen_string_literal: true

class RemoveConfigurableFromStates < ActiveRecord::Migration[5.0]
  def change
    remove_column :states, :configurable, :boolean, default: false
  end
end
