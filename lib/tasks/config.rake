# frozen_string_literal: true

namespace :config do
  desc "Outputs the correct number to set the DB_POOL to"
  task check_db_pool: :environment do
    sidekiq_concurrency = ENV.fetch("SIDEKIQ_CONCURRENCY", 1).to_i
    max_threads = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
    web_concurrency = ENV.fetch("WEB_CONCURRENCY", 1).to_i
    db_pool = ENV.fetch("DB_POOL", 1).to_i
    required_pool = [sidekiq_concurrency, max_threads * web_concurrency].max
    text = <<~TEXT

      In #{Rails.env}, we currently have:

        `SIDEKIQ_CONCURRENCY` => #{sidekiq_concurrency}
        `RAILS_MAX_THREADS`   => #{max_threads}
        `WEB_CONCURRENCY`     => #{web_concurrency}
        `DB_POOL`             => #{db_pool}

      This means that we need a pool size of:

      ```
            [SIDEKIQ_CONCURRENCY, MAX_THREADS*WEB_CONCURRENCY].max
            => [#{sidekiq_concurrency}, #{max_threads}*#{web_concurrency}].max
            => #{required_pool}
      ```

      The current pool size is `#{ActiveRecord::Base.connection_pool.size}`.
    TEXT
    puts text
  end
end
