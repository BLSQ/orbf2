class AddInvoiceAppPathToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :invoice_app_path, :string, null: false, default: "/api/apps/ORBF2---Invoices-and-Reports/index.html"
  end
end