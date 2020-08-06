class AddInvoicingJobToDhis2Logs < ActiveRecord::Migration[5.2]
  def change
    add_reference :dhis2_logs, :invoicing_job, foreign_key: true
    add_column :dhis2_logs, :sidekiq_job_ref, :string, null: true
  end
end
