class BackfillTypeForInvoicingJobs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    InvoicingJob.in_batches.update_all type: "InvoicingJob"
  end
end
