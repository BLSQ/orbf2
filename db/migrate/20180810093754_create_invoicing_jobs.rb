# frozen_string_literal: true

class CreateInvoicingJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :invoicing_jobs do |t|
      t.references :project_anchor, foreign_key: true, null: false
      t.string :orgunit_ref, null: false
      t.string :dhis2_period, null: false
      t.string :user_ref
      t.timestamp :processed_at
      t.timestamp :errored_at
      t.string :last_error
      t.integer :duration_ms
      t.string :status
      t.string :sidekiq_job_ref
    end
  end
end
