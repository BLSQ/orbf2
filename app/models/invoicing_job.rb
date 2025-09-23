# frozen_string_literal: true

# == Schema Information
#
# Table name: invoicing_jobs
#
#  id                :bigint(8)        not null, primary key
#  dhis2_period      :string           not null
#  duration_ms       :integer
#  errored_at        :datetime
#  last_error        :string
#  orgunit_ref       :string           not null
#  processed_at      :datetime
#  sidekiq_job_ref   :string
#  status            :string           default("enqueued")
#  type              :string           default("InvoicingJob")
#  user_ref          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_anchor_id :integer          not null
#
# Indexes
#
#  index_invoicing_jobs_on_anchor_ou_period   (project_anchor_id,orgunit_ref,dhis2_period,type) UNIQUE
#  index_invoicing_jobs_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

class InvoicingJob < ApplicationRecord
  belongs_to :project_anchor, inverse_of: :invoicing_jobs

  has_many :dhis2_logs, dependent: :destroy

  has_one_attached :result

  validates :dhis2_period, presence: true
  validates :orgunit_ref, presence: true

  enum status: {
    enqueued:  "enqueued",
    processed: "processed",
    errored:   "errored"
  }

  class LogSubscriber < ActiveSupport::LogSubscriber
    def execute(event)
      found = color(event.payload[:found], CYAN)
      processed = color(event.payload[:processed], CYAN)
      info "[InvoicingJob] #{found}"
      info "[InvoicingJob] #{processed}"
    end
  end
  # If we want the metrics
  # InvoicingJob::LogSubscriber.attach_to :invoicing_job

  class << self
    def execute(project_anchor, period, orgunit_ref)

      quarter_period = period.gsub("NovQ","Q")

      invoicing_job = find_invoicing_job(project_anchor, quarter_period, orgunit_ref)
      start_time = time

      instrument :execute do |payload|
        begin
          payload[:found] = "FOUND #{invoicing_job.inspect} vs #{period} #{quarter_period} #{orgunit_ref}"
          yield(invoicing_job)
        ensure
          payload[:processed] = "mark_as_processed #{invoicing_job.inspect}"
          find_invoicing_job(project_anchor, quarter_period, orgunit_ref)&.mark_as_processed(start_time, time)
        end
      end
    rescue StandardError => err
      warn "ERROR #{invoicing_job.inspect} #{err.message}"
      find_invoicing_job(project_anchor, quarter_period, orgunit_ref)&.mark_as_error(start_time, time, err)
      raise err
    end

    private

    def instrument(operation, payload = {}, &block)
      ActiveSupport::Notifications.instrument(
        "#{operation}.#{name.underscore}",
        payload, &block
      )
    end

    def time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def scope_for(project_anchor)
      project_anchor.invoicing_jobs
    end

    def find_invoicing_job(project_anchor, period, orgunit_ref)
      scope_for(project_anchor).find_by(
        dhis2_period: period,
        orgunit_ref:  orgunit_ref
      )
    end
  end

  def processed_after?(time_stamp: 10.minutes.ago)
    return errored_at && errored_at > time_stamp if errored? && errored_at
    return processed_at && processed_at > time_stamp if processed? && processed_at

    false
  end

  def alive?
    return false if processed? || errored?
    return false unless updated_at
    return false if updated_at < 1.day.ago

    true
  end

  def result_url
    result&.service_url(content_type: "application/json") if result.attached?
  end

  def mark_as_processed(start_time, end_time)
    transaction(requires_new: true) do
      fill_duration(start_time, end_time)
      self.processed_at = Time.now
      self.errored_at = nil
      self.status = InvoicingJob.statuses[:processed]
      self.last_error = nil
      save!
    end
    reload
  end

  def mark_as_error(start_time, end_time, err)
    transaction(requires_new: true) do
      fill_duration(start_time, end_time)
      self.processed_at = nil
      self.errored_at = Time.now
      self.status = InvoicingJob.statuses[:errored]
      self.last_error = "#{err&.class&.name}: #{err&.message}"
      save!
    end
  end

  def org_unit_name
    autocompleter = Autocomplete::Dhis2.new(project_anchor)
    autocompleter.find(orgunit_ref, kind: "organisation_units").first&.display_name
  end

  private

  def fill_duration(start_time, end_time)
    self.duration_ms = (end_time - start_time) * 1000
  end
end
