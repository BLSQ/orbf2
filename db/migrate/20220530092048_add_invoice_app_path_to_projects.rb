class AddInvoiceAppPathToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :invoice_app_path, :string, null: true
  end
end