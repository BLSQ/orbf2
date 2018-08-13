# frozen_string_literal: true

# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :integer          not null, primary key
#  project_anchor_id :integer          not null
#  orgunit_ref       :string           not null
#  dhis2_period      :string           not null
#  user_ref          :string           not null
#  processed_at      :datetime
#  errored_at        :datetime
#  duration_ms       :integer
#  status            :string           not null
#  sidekiq_job_ref   :string           not null
#

class InvoicingJob < ApplicationRecord
  belongs_to :project_anchor, inverse_of: :invoicing_jobs

  class << self
    def execute(project_anchor, period, orgunit_ref)
      start_time = time
      invoicing_job = find_invoicing_job(project_anchor, period, orgunit_ref)
      yield
      invoicing_job&.mark_as_processed(start_time, time)
    rescue StandardError => err
      invoicing_job&.mark_as_error(start_time, time, err)
      raise err
    end

    private

    def time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def find_invoicing_job(project_anchor, period, orgunit_ref)
      project_anchor.invoicing_jobs.find_by(
        dhis2_period: period,
        orgunit_ref:  orgunit_ref
      )
    end
  end


  def mark_as_processed(start_time, end_time)
    fill_duration(start_time, end_time)
    self.processed_at = Time.now
    self.errored_at = nil
    self.status = "processed"
    self.last_error = nil
    save!
  end

  def mark_as_error(start_time, end_time, err)
    fill_duration(start_time, end_time)
    self.processed_at = nil
    self.errored_at = Time.now
    self.status = "errored"
    self.last_error = "#{err.class.name}: #{err.message}"
    save!
  end



  private

  def fill_duration(start_time, end_time)
    self.duration_ms = (end_time - start_time) * 1000
  end
end
