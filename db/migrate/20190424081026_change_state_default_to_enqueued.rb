class ChangeStateDefaultToEnqueued < ActiveRecord::Migration[5.2]
  def change
    # Change the default from nil to 'enqueued'
    # Backfilling is not needed, I checked and all job's have a status already. This will only
    # affect new jobs.
    change_column_default :invoicing_jobs, :status, from: nil, to: InvoicingJob.statuses[:enqueued]
  end
end
