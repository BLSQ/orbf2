# frozen_string_literal: true

class AddDegExternalReferenceToPackage < ActiveRecord::Migration[5.2]
  def change
    add_column :packages, :deg_external_reference, :string, null: true
  end
end
