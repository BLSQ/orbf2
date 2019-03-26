# frozen_string_literal: true
# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :integer          not null, primary key
#  dhis2_period      :string           not null
#  duration_ms       :integer
#  errored_at        :datetime
#  last_error        :string
#  orgunit_ref       :string           not null
#  processed_at      :datetime
#  sidekiq_job_ref   :string
#  status            :string
#  user_ref          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_anchor_id :integer          not null
#
# Indexes
#
#  index_invoicing_jobs_on_anchor_ou_period   (project_anchor_id,orgunit_ref,dhis2_period) UNIQUE
#  index_invoicing_jobs_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

class InvoicingJob < ApplicationRecord
  belongs_to :project_anchor, inverse_of: :invoicing_jobs

  class << self
    def execute(project_anchor, period, orgunit_ref)
      start_time = time
      find_invoicing_job(project_anchor, period, orgunit_ref)
      begin
        yield
      ensure
        find_invoicing_job(project_anchor, period, orgunit_ref)&.mark_as_processed(start_time, time)
      end
    rescue StandardError => err
      find_invoicing_job(project_anchor, period, orgunit_ref)&.mark_as_error(start_time, time, err)
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

  def alive?
    return false if status == "processed" || status == "errored"
    return false if updated_at < 1.day.ago
    true
  end

  def mark_as_processed(start_time, end_time)
    transaction(requires_new: true) do
      fill_duration(start_time, end_time)
      self.processed_at = Time.now
      self.errored_at = nil
      self.status = "processed"
      self.last_error = nil
      save!
    end
    self.reload
    puts "mark_as_processed requires_new #{self.inspect}"
  end

  def mark_as_error(start_time, end_time, err)
    transaction(requires_new: true) do
      fill_duration(start_time, end_time)
      self.processed_at = nil
      self.errored_at = Time.now
      self.status = "errored"
      self.last_error = "#{err&.class&.name}: #{err&.message}"
      save!
    end
  end

  private

  def fill_duration(start_time, end_time)
    self.duration_ms = (end_time - start_time) * 1000
  end
end
