# frozen_string_literal: true

class AddExportableFomulaCodeToFormulas < ActiveRecord::Migration[5.0]
  def change
    add_column :formulas, :exportable_formula_code, :string, null: true
  end
end
