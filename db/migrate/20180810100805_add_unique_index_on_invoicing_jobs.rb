# frozen_string_literal: true

class AddUniqueIndexOnInvoicingJobs < ActiveRecord::Migration[5.0]
  def change
    add_index :invoicing_jobs, %i[project_anchor_id orgunit_ref dhis2_period], unique: true, name: 'index_invoicing_jobs_on_anchor_ou_period'
  end
end
