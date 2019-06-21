# frozen_string_literal: true

module Api
  class WorkersController < Api::ApplicationController
    def index
      if (request.headers["X-Token"] || params[:token]) != ENV.fetch("MONITORING_TOKEN")
        render json: { message: "unauthorized" }, status: :unauthorized
        return
      end

      render(
        json:   {
          timestamps: {
            requested: Time.now.to_s(:db)
          },
          sidekiq:    sidekiq_infos,
          invoicing:  invoicing_infos
        },
        status: sidekiq_stats.enqueued > 250 ? :service_unavailable : :ok
      )
    end

    private

    def sidekiq_infos
      {
        active_workers: sidekiq_stats.workers_size,
        queue_sizes:    sidekiq_queue_sizes,
        latency:        Sidekiq::Queue.new.latency,
        recent_history: {
          processed: sidekiq_history.processed,
          failed:    sidekiq_history.failed
        },
        totals:         {
          processed: sidekiq_stats.processed,
          failed:    sidekiq_stats.failed
        }
      }
    end

    def invoicing_infos
      {
        last_day_stats: InvoicingJob.where("status in ('enqueued', 'errored', 'processed')")
                                    .where("created_at > ? ", Time.now - 1.day)
                                    .select("project_anchor_id, count(*), status")
                                    .group("project_anchor_id, status").map do |j|
                          { id:     j.project_anchor.id,
                            code:   j.project_anchor.program.code,
                            status: j.status,
                            count:  j.count }
                        end
      }
    end

    def sidekiq_stats
      @sidekiq_stats ||= Sidekiq::Stats.new
    end

    def sidekiq_history
      @sidekiq_history ||= Sidekiq::Stats::History.new(5)
    end

    def sidekiq_queue_sizes
      queue_sizes = sidekiq_stats.queues

      queue_sizes.merge(
        scheduled: sidekiq_stats.scheduled_size,
        retries:   sidekiq_stats.retry_size,
        dead:      sidekiq_stats.dead_size
      )
    end
  end
end
