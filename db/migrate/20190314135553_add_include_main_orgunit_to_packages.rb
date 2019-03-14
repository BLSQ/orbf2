# frozen_string_literal: true

class AddIncludeMainOrgunitToPackages < ActiveRecord::Migration[5.2]
  def change
    add_column :packages, :include_main_orgunit, :boolean, default: false, null: false
  end
end
