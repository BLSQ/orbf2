class AddTypeToInvoicingJobs < ActiveRecord::Migration[5.2]
  def change
    # Add the type column (without a default)
    add_column :invoicing_jobs, :type, :string

    # Change the default from nil to InvoicingJob
    # Backfilling will be done in other migration
    change_column_default :invoicing_jobs, :type, from: nil, to: "InvoicingJob"

    # Remove the old index that didn't use the type
    remove_index :invoicing_jobs, name: 'index_invoicing_jobs_on_anchor_ou_period'

    # Add index that does use the type
    add_index :invoicing_jobs, %i[project_anchor_id orgunit_ref dhis2_period type], unique: true, name: 'index_invoicing_jobs_on_anchor_ou_period'
  end
end
