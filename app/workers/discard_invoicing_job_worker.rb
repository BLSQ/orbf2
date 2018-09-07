# frozen_string_literal: true

class DiscardInvoicingJobWorker
  include Sidekiq::Worker

  def perform
    alive_jids = jids
    puts "DiscardInvoicingJobWorker invoicing_jobs : #{invoicing_jobs.size} vs scheduled and running workers #{alive_jids.size}"

    invoicing_jobs.each do |invoicing_job|
      unless alive_jids.include?(invoicing_job.sidekiq_job_ref)
        invoicing_job.update!(status: "errored")
      end
    end
  end

  def invoicing_jobs
    InvoicingJob.where(status: "enqueued")
                .where("updated_at < ?", 2.minutes.ago)
  end

  def jids
    Set.new.merge(Sidekiq::ScheduledSet.new.select.map(&:jid))
       .merge(Sidekiq::RetrySet.new.select.map(&:jid))
       .merge(Sidekiq::Queue.new("default").map(&:jid))
       .merge(Sidekiq::Workers.new.map { |_process, _thread, msg| msg["payload"]["jid"] })
  end
end
